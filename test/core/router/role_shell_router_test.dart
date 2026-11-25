import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teletech_drivers/app.dart';
import 'package:teletech_drivers/core/errors/failures.dart';
import 'package:teletech_drivers/core/presentation/glass_bottom_bar.dart';
import 'package:teletech_drivers/core/router/app_router.dart';
import 'package:teletech_drivers/core/router/app_routes.dart';
import 'package:teletech_drivers/core/session/session_uid_source.dart';
import 'package:teletech_drivers/features/admin/presentation/providers/employee_providers.dart';
import 'package:teletech_drivers/features/admin/presentation/providers/user_account_providers.dart';
import 'package:teletech_drivers/features/auth/data/providers/auth_repository_provider.dart';
import 'package:teletech_drivers/features/auth/domain/entities/app_user.dart';
import 'package:teletech_drivers/features/auth/domain/entities/branch.dart';
import 'package:teletech_drivers/features/auth/domain/entities/profile_patch.dart';
import 'package:teletech_drivers/features/auth/domain/entities/user_role.dart';
import 'package:teletech_drivers/features/auth/domain/repositories/auth_repository.dart';
import 'package:teletech_drivers/features/attendance/domain/entities/attendance_day.dart';
import 'package:teletech_drivers/features/attendance/domain/entities/attendance_today.dart';
import 'package:teletech_drivers/features/attendance/presentation/providers/attendance_providers.dart';
import 'package:teletech_drivers/features/company_admin/presentation/screens/company_admin_request_details_screen.dart';
import 'package:teletech_drivers/features/auth/presentation/providers/splash_gate.dart';
import 'package:teletech_drivers/features/auth/presentation/screens/forced_change_password_screen.dart';
import 'package:teletech_drivers/features/driver/presentation/screens/driver_home_screen.dart';
import 'package:teletech_drivers/features/driver/presentation/screens/driver_trip_details_screen.dart';
import 'package:teletech_drivers/features/drivers_admin/domain/entities/driver_private_profile.dart';
import 'package:teletech_drivers/features/drivers_admin/domain/entities/driver_profile.dart';
import 'package:teletech_drivers/features/driver_stats/domain/entities/driver_stats.dart';
import 'package:teletech_drivers/features/driver_stats/presentation/providers/driver_stats_providers.dart';
import 'package:teletech_drivers/features/drivers_admin/presentation/providers/driver_providers.dart';
import 'package:teletech_drivers/features/drivers_admin/presentation/screens/driver_details_screen.dart';
import 'package:teletech_drivers/features/trip/presentation/controllers/created_by_me_trips_controller.dart';
import 'package:teletech_drivers/features/drivers_admin/presentation/screens/drivers_admin_trip_details_screen.dart';
import 'package:teletech_drivers/features/place/domain/entities/place.dart';
import 'package:teletech_drivers/features/place/presentation/providers/place_providers.dart';
import 'package:teletech_drivers/features/tracking/domain/entities/live_map_driver.dart';
import 'package:teletech_drivers/features/tracking/presentation/providers/tracking_providers.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip.dart';
import 'package:teletech_drivers/features/trip/presentation/providers/trip_providers.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request.dart';
import 'package:teletech_drivers/features/trip_request/presentation/providers/trip_request_providers.dart';
import 'package:teletech_drivers/features/trip_request/presentation/screens/new_trip_request_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final cases = <UserRole, _Case>{
    UserRole.employee: _Case(
      home: AppRoutes.employeeHome,
      detail: AppRoutes.employeeNewRequest,
      detailFinder: find.byType(NewTripRequestScreen),
    ),
    UserRole.driver: _Case(
      home: AppRoutes.driverHome,
      detail: '/driver/trips/t1',
      detailFinder: find.byType(DriverTripDetailsScreen),
    ),
    UserRole.companyAdmin: _Case(
      home: AppRoutes.companyAdminHome,
      detail: '/company-admin/requests/req-1',
      detailFinder: find.byType(CompanyAdminRequestDetailsScreen),
    ),
    UserRole.driversAdmin: _Case(
      home: AppRoutes.driversAdminHome,
      detail: '/drivers-admin/trips/t1?assign=1',
      detailFinder: find.byType(DriversAdminTripDetailsScreen),
    ),
    UserRole.admin: _Case(
      home: AppRoutes.adminDashboard,
      detail: '/admin/drivers/d1',
      detailFinder: find.byType(DriverDetailsScreen),
    ),
  };

  for (final entry in cases.entries) {
    testWidgets(
      '${entry.key.name} shows the bar on the home tab and hides it on a detail',
      (tester) async {
        final container = await _pumpRole(tester, entry.key);
        expect(find.byKey(GlassBottomBar.barKey).hitTestable(), findsOneWidget);
        expect(find.byType(NavigationRail), findsNothing);
        expect(_location(container), entry.value.home);

        container.read(appRouterProvider).go(entry.value.detail);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(entry.value.detailFinder, findsOneWidget);
        expect(find.byKey(GlassBottomBar.barKey).hitTestable(), findsNothing);
      },
    );
  }

  for (final role in UserRole.values) {
    testWidgets('${role.name} keeps the bottom bar on a wide window', (
      tester,
    ) async {
      await _pumpRole(tester, role, size: const Size(1400, 900));
      expect(find.byKey(GlassBottomBar.barKey).hitTestable(), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
    });
  }

  testWidgets('employee plus opens the new trip request screen', (
    tester,
  ) async {
    await _pumpRole(tester, UserRole.employee);
    final fab = find.byType(FloatingActionButton);
    expect(fab.hitTestable(), findsOneWidget);

    await tester.tap(fab);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(NewTripRequestScreen), findsOneWidget);
    expect(find.byKey(GlassBottomBar.barKey).hitTestable(), findsNothing);
  });

  testWidgets('driver opens home after a temporary password is replaced', (
    tester,
  ) async {
    final auth = _MutableRouterAuth(
      _user(UserRole.driver).copyWithMustChangePassword(true),
    );
    addTearDown(auth.dispose);
    final container = await _pumpRole(tester, UserRole.driver, auth: auth);

    expect(_location(container), AppRoutes.changePasswordRequired);
    expect(find.byType(ForcedChangePasswordScreen), findsOneWidget);

    auth.emit(_user(UserRole.driver));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(_location(container), AppRoutes.driverHome);
    expect(find.byType(DriverHomeScreen), findsOneWidget);
  });

  testWidgets('employee cannot open a company admin route', (tester) async {
    final container = await _pumpRole(tester, UserRole.employee);
    container.read(appRouterProvider).go(AppRoutes.companyAdminHome);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(_location(container), AppRoutes.employeeHome);
    expect(find.byKey(GlassBottomBar.barKey).hitTestable(), findsOneWidget);
  });
}

class _Case {
  const _Case({
    required this.home,
    required this.detail,
    required this.detailFinder,
  });

  final String home;
  final String detail;
  final Finder detailFinder;
}

Future<ProviderContainer> _pumpRole(
  WidgetTester tester,
  UserRole role, {
  Size size = const Size(800, 600),
  AuthRepository? auth,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);

  final container = ProviderContainer(
    overrides: [
      splashMinimumDurationProvider.overrideWithValue(Duration.zero),
      authRepositoryProvider.overrideWithValue(
        auth ?? _RouterAuth(_user(role)),
      ),
      employeeTripRequestsProvider.overrideWith(
        (ref) => Stream<List<TripRequest>>.value(const []),
      ),
      myTripRequestsProvider.overrideWith(
        (ref, bucket) => Stream<List<TripRequest>>.value(const []),
      ),
      awaitingConfirmationProvider.overrideWith(
        (ref) => Stream<List<TripRequest>>.value(const []),
      ),
      pendingTripRequestsProvider.overrideWith(
        (ref) => Stream<List<TripRequest>>.value(const []),
      ),
      allTripRequestsProvider.overrideWith(
        (ref) => Stream<List<TripRequest>>.value(const []),
      ),
      adminTripRequestsProvider.overrideWith(
        (ref, query) => Stream<List<TripRequest>>.value(const []),
      ),
      tripsQueryProvider.overrideWith(
        (ref, query) => Stream<List<Trip>>.value(const []),
      ),
      driverProfilesByAttendanceProvider.overrideWith(
        (ref, attendance) => Stream<List<DriverProfile>>.value(const []),
      ),
      attendanceTodayProvider.overrideWith(
        (ref) async => const AttendanceToday(
          workDate: '2026-11-22',
          status: 'not_checked_in',
        ),
      ),
      myAttendanceProvider.overrideWith(
        (ref, query) async => const AttendanceHistory(
          days: [],
          totals: AttendanceTotals(
            daysPresent: 0,
            daysAbsent: 0,
            totalOnSiteHours: 0,
          ),
        ),
      ),
      driverAttendanceProvider.overrideWith(
        (ref, query) async => const AttendanceHistory(
          days: [],
          totals: AttendanceTotals(
            daysPresent: 0,
            daysAbsent: 0,
            totalOnSiteHours: 0,
          ),
        ),
      ),
      createdByMeTripsProvider.overrideWith2(_EmptyCreatedByMe.new),
      adminDriverStatsProvider.overrideWith(
        (ref, driverId) async => const DriverStats(
          period: 'week',
          trips: 0,
          totalSeconds: 0,
          totalKm: 0,
          breakdown: [],
        ),
      ),
      adminDriverTripsProvider.overrideWith((ref, driverId) async => const []),
      approvedAwaitingTripRequestsProvider.overrideWith(
        (ref) => Stream<List<TripRequest>>.value(const []),
      ),
      tripRequestByIdProvider.overrideWith((ref, id) async => null),
      allTripsProvider.overrideWith(
        (ref) => Stream<List<Trip>>.value(const []),
      ),
      driverTripsProvider.overrideWith(
        (ref, driverId) => Stream<List<Trip>>.value(const []),
      ),
      watchTripByIdProvider.overrideWith(
        (ref, tripId) => Stream<Trip?>.value(null),
      ),
      allDriversProvider.overrideWith(
        (ref) => Stream<List<AppUser>>.value(const []),
      ),
      allDriverProfilesProvider.overrideWith(
        (ref) => Stream<List<DriverProfile>>.value(const []),
      ),
      driverProfileProvider.overrideWith((ref, id) async => _profile(id)),
      allEmployeesProvider.overrideWith(
        (ref) => Stream<List<AppUser>>.value(const []),
      ),
      allUserAccountsProvider.overrideWith(
        (ref) => Stream<List<AppUser>>.value(const []),
      ),
      allPlacesProvider.overrideWith(
        (ref) => Stream<List<Place>>.value(const []),
      ),
      activePlacesProvider.overrideWith(
        (ref) => Stream<List<Place>>.value(const []),
      ),
      adminLiveMapLocationsProvider.overrideWith(
        (ref, driverId) => Stream<List<LiveMapDriver>>.value(const []),
      ),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(container: container, child: const TeleTechApp()),
  );
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  return container;
}

String _location(ProviderContainer container) {
  return container.read(appRouterProvider).state.matchedLocation;
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

DriverProfile _profile(String id) {
  return DriverProfile(
    id: id,
    nameEn: 'Omar',
    nameAr: 'عمر',
    email: 'omar@test.com',
    phone: '0100',
    isActive: true,
    privateProfile: const DriverPrivateProfile(
      nationalId: '',
      carLicense: '',
      personalLicense: '',
    ),
  );
}

class _EmptyCreatedByMe extends CreatedByMeTripsController {
  _EmptyCreatedByMe(super.bucket);

  @override
  Future<CreatedByMeList> build() async {
    return const CreatedByMeList(trips: [], page: 1, hasMore: false);
  }
}

class _MutableRouterAuth extends _RouterAuth {
  _MutableRouterAuth(super.user);

  final _updates = StreamController<AppUser?>.broadcast();

  void emit(AppUser? next) {
    user = next;
    if (!_updates.isClosed) _updates.add(next);
  }

  void dispose() {
    unawaited(_updates.close());
  }

  @override
  Stream<AppUser?> authStateChanges() {
    return Stream<AppUser?>.multi((controller) {
      controller.add(user);
      final subscription = _updates.stream.listen(controller.add);
      controller.onCancel = subscription.cancel;
    });
  }
}

class _RouterAuth implements AuthRepository, SessionUidSource {
  _RouterAuth(this.user);

  AppUser? user;

  @override
  String? get currentUserId => user?.id;

  @override
  Stream<AppUser?> authStateChanges() => Stream.value(user);

  @override
  Stream<Failure> watchSessionFailures() => const Stream.empty();

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {}

  @override
  Future<void> completeEmployeeProfile({
    required String uid,
    required String phone,
    required Branch branch,
  }) async {}

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
  }) async {}

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<void> updateProfile(ProfilePatch patch) async {}
}
