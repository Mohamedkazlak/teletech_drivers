import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teletech_drivers/core/constants/api_json_keys.dart';
import 'package:teletech_drivers/core/errors/failures.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/theme/app_theme.dart';
import 'package:teletech_drivers/features/auth/data/providers/auth_repository_provider.dart';
import 'package:teletech_drivers/features/auth/domain/entities/app_user.dart';
import 'package:teletech_drivers/features/auth/domain/entities/branch.dart';
import 'package:teletech_drivers/features/auth/domain/entities/profile_patch.dart';
import 'package:teletech_drivers/features/auth/domain/entities/user_role.dart';
import 'package:teletech_drivers/features/auth/domain/repositories/auth_repository.dart';
import 'package:teletech_drivers/features/auth/presentation/providers/auth_providers.dart';
import 'package:teletech_drivers/features/auth/presentation/screens/profile_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _ProfileAuth auth;

  setUp(() {
    auth = _ProfileAuth(
      AppUser(
        id: 'u1',
        name: 'Ada',
        nameEn: 'Ada',
        email: 'ada@test.com',
        role: UserRole.employee,
        phone: '0100',
        branch: Branch.companyHeadquarters,
      ),
    );
  });

  tearDown(() => auth.dispose());

  Future<ProviderContainer> pumpProfile(WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(auth)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const ProfileScreen(),
        ),
      ),
    );
    await tester.pump();
    return container;
  }

  testWidgets('requires a name before saving', (tester) async {
    await pumpProfile(tester);
    await tester.enterText(find.byType(TextFormField).first, '');
    await tester.tap(find.text('Save profile'));
    await tester.pump();
    expect(find.text('Enter your name.'), findsOneWidget);
  });

  testWidgets('saves and refreshes the session user', (tester) async {
    final container = await pumpProfile(tester);
    await tester.enterText(find.byType(TextFormField).first, 'Ada Lovelace');
    await tester.tap(find.text('Save profile'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Profile saved'), findsOneWidget);
    expect(
      container.read(currentUserProvider).asData?.value?.name,
      'Ada Lovelace',
    );
    expect(auth.lastPatch?.nameEn, 'Ada Lovelace');
    expect(auth.lastPatch?.email, isNull);
    expect(auth.lastPatch?.nameArChanged, isFalse);
    expect(auth.lastPatch?.phoneChanged, isFalse);
    expect(auth.lastPatch?.branchChanged, isFalse);
  });

  testWidgets('maps 422 field errors onto the fields', (tester) async {
    auth.profileError = const ValidationFailure(
      fieldErrors: {
        ApiJsonKeys.nameEn: ['Already used'],
        ApiJsonKeys.phone: ['Invalid phone'],
      },
    );
    await pumpProfile(tester);
    await tester.enterText(find.byType(TextFormField).first, 'Ada Updated');
    await tester.tap(find.text('Save profile'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Already used'), findsOneWidget);
    expect(find.text('Invalid phone', skipOffstage: false), findsOneWidget);
    expect(find.text('Profile saved'), findsNothing);
  });

  testWidgets('shows branch as read-only for an employee', (tester) async {
    await pumpProfile(tester);
    expect(find.byType(DropdownButtonFormField<Branch>), findsNothing);
    expect(
      find.text('Contact the admin to change your branch.'),
      findsOneWidget,
    );
    expect(find.text('Company Headquarters'), findsOneWidget);
  });

  testWidgets('lets a system admin edit the branch', (tester) async {
    auth.user = AppUser(
      id: 'u1',
      name: 'Ada',
      nameEn: 'Ada',
      email: 'ada@test.com',
      role: UserRole.admin,
      phone: '0100',
      branch: Branch.companyHeadquarters,
    );
    await pumpProfile(tester);
    expect(find.byType(DropdownButtonFormField<Branch>), findsOneWidget);
    expect(find.text('Contact the admin to change your branch.'), findsNothing);
  });
}

class _ProfileAuth implements AuthRepository {
  _ProfileAuth(this.user);

  AppUser? user;
  Object? profileError;
  ProfilePatch? lastPatch;
  final _users = StreamController<AppUser?>.broadcast();

  @override
  Stream<AppUser?> authStateChanges() async* {
    yield user;
    yield* _users.stream;
  }

  @override
  Stream<Failure> watchSessionFailures() => const Stream.empty();

  @override
  Future<void> updateProfile(ProfilePatch patch) async {
    if (profileError != null) throw profileError!;
    lastPatch = patch;
    final current = user!;
    user = AppUser(
      id: current.id,
      name: patch.nameEn ?? current.name,
      nameEn: patch.nameEn ?? current.nameEn,
      nameAr: patch.nameArChanged ? patch.nameAr : current.nameAr,
      email: patch.email ?? current.email,
      role: current.role,
      phone: patch.phoneChanged ? patch.phone : current.phone,
      branch: patch.branchChanged ? patch.branch : current.branch,
    );
    _users.add(user);
  }

  void dispose() => _users.close();

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) => throw UnimplementedError();

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

  @override
  Future<void> signOut() async {
    user = null;
    _users.add(null);
  }
}
