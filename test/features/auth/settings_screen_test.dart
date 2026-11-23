import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teletech_drivers/core/constants/api_json_keys.dart';
import 'package:teletech_drivers/core/errors/failures.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/localization/locale_controller.dart';
import 'package:teletech_drivers/core/localization/locale_store.dart';
import 'package:teletech_drivers/core/network/api_client.dart';
import 'package:teletech_drivers/core/network/api_exception.dart';
import 'package:teletech_drivers/core/theme/app_theme.dart';
import 'package:teletech_drivers/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:teletech_drivers/features/auth/data/models/auth_token_dto.dart';
import 'package:teletech_drivers/features/auth/data/models/user_dto.dart';
import 'package:teletech_drivers/features/auth/data/providers/auth_repository_provider.dart';
import 'package:teletech_drivers/features/auth/data/repositories/api_auth_repository.dart';
import 'package:teletech_drivers/features/auth/domain/entities/app_user.dart';
import 'package:teletech_drivers/features/auth/domain/entities/branch.dart';
import 'package:teletech_drivers/features/auth/domain/entities/profile_patch.dart';
import 'package:teletech_drivers/features/auth/domain/entities/user_role.dart';
import 'package:teletech_drivers/features/auth/domain/repositories/auth_repository.dart';
import 'package:teletech_drivers/features/auth/presentation/providers/auth_providers.dart';
import 'package:teletech_drivers/features/auth/presentation/screens/settings_screen.dart';
import 'package:teletech_drivers/features/tracking/presentation/controllers/location_tracking_controller.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_status.dart';
import 'package:teletech_drivers/features/trip/presentation/providers/trip_providers.dart';

import '../../core/network/fake_token_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<ProviderContainer> pumpSettings(
    WidgetTester tester, {
    required AuthRepository auth,
    _SpyTracking? tracking,
    bool driverOnTrip = false,
  }) async {
    final spy = tracking;
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        if (spy != null)
          locationTrackingControllerProvider.overrideWith(() => spy),
        if (driverOnTrip)
          driverTripsProvider.overrideWith(
            (ref, driverId) => Stream.value([_goingTrip()]),
          ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const _SettingsHost(),
      ),
    );
    await tester.pump();
    return container;
  }

  testWidgets('language switch persists and flips direction', (tester) async {
    final auth = _SettingsAuth(_user(UserRole.employee));
    addTearDown(auth.dispose);
    await pumpSettings(tester, auth: auth);

    await tester.tap(find.text('Arabic'));
    await tester.pump();
    await tester.pump();

    expect(find.text('الإعدادات'), findsWidgets);
    expect(
      Directionality.of(tester.element(find.text('اللغة'))),
      TextDirection.rtl,
    );
    expect((await LocaleStore.read()).languageCode, 'ar');

    final restored = ProviderContainer(
      overrides: [
        initialLocaleProvider.overrideWithValue(await LocaleStore.read()),
        authRepositoryProvider.overrideWithValue(auth),
      ],
    );
    addTearDown(restored.dispose);
    expect(restored.read(localeControllerProvider).languageCode, 'ar');
  });

  testWidgets('change password success clears the form', (tester) async {
    final auth = _SettingsAuth(_user(UserRole.employee));
    addTearDown(auth.dispose);
    await pumpSettings(tester, auth: auth);

    await tester.enterText(find.byType(TextFormField).at(0), 'password1');
    await tester.enterText(find.byType(TextFormField).at(1), 'password2');
    await tester.enterText(find.byType(TextFormField).at(2), 'password2');
    await tester.ensureVisible(find.text('Update password'));
    await tester.tap(find.text('Update password'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Password updated'), findsOneWidget);
    for (final field in tester.widgetList<TextFormField>(
      find.byType(TextFormField),
    )) {
      expect(field.controller?.text, isEmpty);
    }
    expect(auth.passwordChanged, isTrue);
  });

  testWidgets('422 wrong current password shows on that field', (tester) async {
    final auth = _SettingsAuth(_user(UserRole.employee));
    auth.passwordError = const ValidationFailure(
      fieldErrors: {
        ApiJsonKeys.currentPassword: ['Wrong password'],
      },
    );
    addTearDown(auth.dispose);
    await pumpSettings(tester, auth: auth);

    await tester.enterText(find.byType(TextFormField).at(0), 'password1');
    await tester.enterText(find.byType(TextFormField).at(1), 'password2');
    await tester.enterText(find.byType(TextFormField).at(2), 'password2');
    await tester.ensureVisible(find.text('Update password'));
    await tester.tap(find.text('Update password'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Wrong password'), findsOneWidget);
    expect(find.text('Password updated'), findsNothing);
  });

  testWidgets('429 shows the try-again message', (tester) async {
    final auth = _SettingsAuth(_user(UserRole.employee));
    auth.passwordError = const AuthFailure(kind: AuthErrorKind.tooManyRequests);
    addTearDown(auth.dispose);
    await pumpSettings(tester, auth: auth);

    await tester.enterText(find.byType(TextFormField).at(0), 'password1');
    await tester.enterText(find.byType(TextFormField).at(1), 'password2');
    await tester.enterText(find.byType(TextFormField).at(2), 'password2');
    await tester.ensureVisible(find.text('Update password'));
    await tester.tap(find.text('Update password'));
    await tester.pump();
    await tester.pump();

    expect(
      find.text('Too many attempts. Try again in a minute.'),
      findsOneWidget,
    );
  });

  testWidgets('new password shorter than 8 is rejected before the request', (
    tester,
  ) async {
    final auth = _SettingsAuth(_user(UserRole.employee));
    addTearDown(auth.dispose);
    await pumpSettings(tester, auth: auth);

    await tester.enterText(find.byType(TextFormField).at(0), 'secret1');
    await tester.enterText(find.byType(TextFormField).at(1), 'short');
    await tester.enterText(find.byType(TextFormField).at(2), 'short');
    await tester.ensureVisible(find.text('Update password'));
    await tester.tap(find.text('Update password'));
    await tester.pump();

    expect(find.text('Use at least 8 characters.'), findsOneWidget);
    expect(auth.passwordChanged, isFalse);
  });

  testWidgets('logout confirms, warns an active driver, and stops tracking', (
    tester,
  ) async {
    final remote = _LogoutRemote(
      UserDto(
        id: 'drv-1',
        nameEn: 'Omar',
        email: 'omar@test.com',
        role: UserRole.driver,
        isActive: true,
        phone: '0100',
        branch: Branch.newHeadquarters,
      ),
    );
    remote.logoutError = const NetworkApiException();
    final storage = FakeTokenStorage()..token = 'tok';
    final repository = ApiAuthRepository(
      dataSource: remote,
      tokenStorage: storage,
      apiClient: ApiClient(
        tokenStorage: storage,
        baseUrl: 'http://example.test/api',
      ),
    );
    addTearDown(repository.dispose);
    await repository.bootstrap();

    final spy = _SpyTracking();
    final container = await pumpSettings(
      tester,
      auth: repository,
      tracking: spy,
      driverOnTrip: true,
    );
    await tester.pump();

    await tester.ensureVisible(find.text('Sign out'));
    await tester.tap(find.text('Sign out'));
    await tester.pump();
    await tester.pump();

    expect(
      find.text(
        'You have a trip in progress. Signing out stops live tracking.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(spy.stopped, isTrue);
    expect(repository.currentUser, isNull);
    expect(storage.token, isNull);
    expect(container.read(currentUserProvider).asData?.value, isNull);
  });
}

class _SettingsHost extends ConsumerWidget {
  const _SettingsHost();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeControllerProvider);
    return MaterialApp(
      theme: AppTheme.light,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const SettingsScreen(),
    );
  }
}

AppUser _user(UserRole role) {
  return AppUser(
    id: 'u1',
    name: 'Ada',
    email: 'ada@test.com',
    role: role,
    phone: '0100',
    branch: Branch.companyHeadquarters,
  );
}

Trip _goingTrip() {
  final when = DateTime.utc(2026, 11, 3, 8);
  return Trip(
    id: 't1',
    requestIds: const ['r1'],
    passengerIds: const ['e1'],
    passengerNames: const ['Ada'],
    passengerBranches: const [Branch.companyHeadquarters],
    pickupSummary: 'HQ',
    destinationSummary: 'Airport',
    scheduledAt: when,
    status: TripStatus.going,
    createdBy: 'admin',
    createdAt: when,
    driverId: 'drv-1',
  );
}

class _SpyTracking extends LocationTrackingController {
  var stopped = false;

  @override
  Future<void> stopIfNeeded() async {
    stopped = true;
  }
}

class _SettingsAuth implements AuthRepository {
  _SettingsAuth(this.user);

  AppUser? user;
  Object? passwordError;
  var passwordChanged = false;
  final _users = StreamController<AppUser?>.broadcast();

  @override
  Stream<AppUser?> authStateChanges() async* {
    yield user;
    yield* _users.stream;
  }

  @override
  Stream<Failure> watchSessionFailures() => const Stream.empty();

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    if (passwordError != null) throw passwordError!;
    passwordChanged = true;
  }

  @override
  Future<void> signOut() async {
    user = null;
    _users.add(null);
  }

  void dispose() => _users.close();

  @override
  Future<void> updateProfile(ProfilePatch patch) => throw UnimplementedError();

  @override
  Future<void> completeEmployeeProfile({
    required String uid,
    required String phone,
    required Branch branch,
  }) => throw UnimplementedError();

  @override
  Future<void> refreshSession() async {}

  @override
  Future<void> registerEmployee({
    required String name,
    required String nameAr,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String phone,
    required Branch branch,
  }) => throw UnimplementedError();

  @override
  Future<void> signIn({required String email, required String password}) =>
      throw UnimplementedError();
}

class _LogoutRemote implements AuthRemoteDataSource {
  _LogoutRemote(this.me);

  UserDto? me;
  Object? logoutError;

  @override
  Future<UserDto> getMe() async => me!;

  @override
  Future<void> logout() async {
    if (logoutError != null) throw logoutError!;
  }

  @override
  Future<AuthTokenDto> login({
    required String email,
    required String password,
  }) => throw UnimplementedError();

  @override
  Future<UserDto> changePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) => throw UnimplementedError();

  @override
  Future<AuthTokenDto> register({
    required String nameEn,
    required String nameAr,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String phone,
    required Branch branch,
  }) => throw UnimplementedError();

  @override
  Future<UserDto> updateMe(Map<String, Object?> changes) =>
      throw UnimplementedError();
}
