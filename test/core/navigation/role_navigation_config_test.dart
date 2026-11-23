import 'package:flutter_test/flutter_test.dart';
import 'package:teletech_drivers/core/navigation/nav_ids.dart';
import 'package:teletech_drivers/core/navigation/role_navigation_config.dart';
import 'package:teletech_drivers/core/router/app_routes.dart';
import 'package:teletech_drivers/features/auth/domain/entities/user_role.dart';

void main() {
  test('every role config matches forRole and branch order', () {
    for (final role in UserRole.values) {
      final config = RoleNavigationConfig.forRole(role);
      expect(
        config.branches.map((item) => item.id),
        [...config.primary, ...config.overflow].map((item) => item.id),
      );
    }
  });

  test('employee bar is my trips, profile, settings', () {
    const config = RoleNavigationConfig.employee;
    expect(config.primary.map((item) => item.id), [
      NavIds.myTrips,
      NavIds.profile,
      NavIds.settings,
    ]);
    expect(config.primary.map((item) => item.route), [
      AppRoutes.employeeHome,
      AppRoutes.employeeProfile,
      AppRoutes.employeeSettings,
    ]);
    expect(config.overflow, isEmpty);
  });

  test('driver bar is attendance, assigned, completed, stats', () {
    const config = RoleNavigationConfig.driver;
    expect(config.primary.map((item) => item.id), [
      NavIds.attendance,
      NavIds.assignedTrips,
      NavIds.completedTrips,
      NavIds.stats,
    ]);
    expect(config.primary.map((item) => item.route), [
      AppRoutes.driverHome,
      AppRoutes.driverAssignedTrips,
      AppRoutes.driverCompletedTrips,
      AppRoutes.driverStats,
    ]);
    expect(config.overflow.map((item) => item.id), [
      NavIds.profile,
      NavIds.settings,
    ]);
    expect(config.overflow.map((item) => item.route), [
      AppRoutes.driverProfile,
      AppRoutes.driverSettings,
    ]);
  });

  test('company admin bar and more', () {
    const config = RoleNavigationConfig.companyAdmin;
    expect(config.primary.map((item) => item.id), [
      NavIds.requestedTrips,
      NavIds.myTrips,
      NavIds.trips,
      NavIds.places,
    ]);
    expect(config.primary.map((item) => item.route), [
      AppRoutes.companyAdminHome,
      AppRoutes.companyAdminMyTrips,
      AppRoutes.companyAdminTrips,
      AppRoutes.companyAdminPlaces,
    ]);
    expect(config.overflow.map((item) => item.id), [
      NavIds.profile,
      NavIds.settings,
    ]);
    expect(config.overflow.map((item) => item.route), [
      AppRoutes.companyAdminProfile,
      AppRoutes.companyAdminSettings,
    ]);
  });

  test('drivers admin bar and more', () {
    const config = RoleNavigationConfig.driversAdmin;
    expect(config.primary.map((item) => item.id), [
      NavIds.requests,
      NavIds.trips,
      NavIds.attendanceBoard,
      NavIds.drivers,
    ]);
    expect(config.primary.map((item) => item.route), [
      AppRoutes.driversAdminHome,
      AppRoutes.driversAdminTrips,
      AppRoutes.driversAdminAttendance,
      AppRoutes.driversAdminDrivers,
    ]);
    expect(config.overflow.map((item) => item.id), [
      NavIds.myTrips,
      NavIds.liveMap,
      NavIds.profile,
      NavIds.settings,
    ]);
    expect(config.overflow.map((item) => item.route), [
      AppRoutes.driversAdminMyRequests,
      AppRoutes.driversAdminLiveMap,
      AppRoutes.driversAdminProfile,
      AppRoutes.driversAdminSettings,
    ]);
  });

  test('admin bar and more', () {
    const config = RoleNavigationConfig.admin;
    expect(config.primary.map((item) => item.id), [
      NavIds.dashboard,
      NavIds.drivers,
      NavIds.employees,
      NavIds.places,
    ]);
    expect(config.primary.map((item) => item.route), [
      AppRoutes.adminDashboard,
      AppRoutes.adminDrivers,
      AppRoutes.adminEmployees,
      AppRoutes.adminPlaces,
    ]);
    expect(config.overflow.map((item) => item.id), [
      NavIds.users,
      NavIds.myTrips,
      NavIds.profile,
      NavIds.settings,
    ]);
    expect(config.overflow.map((item) => item.route), [
      AppRoutes.adminUsers,
      AppRoutes.adminMyTrips,
      AppRoutes.adminProfile,
      AppRoutes.adminSettings,
    ]);
  });
}
