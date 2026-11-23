import 'package:flutter/material.dart';
import 'package:teletech_drivers/core/navigation/nav_ids.dart';
import 'package:teletech_drivers/core/navigation/nav_item.dart';
import 'package:teletech_drivers/core/navigation/nav_label_key.dart';
import 'package:teletech_drivers/core/router/app_routes.dart';
import 'package:teletech_drivers/features/auth/domain/entities/user_role.dart';

/// Strategy: one pure navigation layout per [UserRole].
///
/// [primary] items are the bar. [overflow] items open from More and are still
/// shell branches (state kept, bar stays visible). Branch order is primary
/// then overflow, which matches [StatefulShellRoute] branch indexes.
final class RoleNavigationConfig {
  const RoleNavigationConfig({required this.primary, required this.overflow});

  final List<NavItem> primary;
  final List<NavItem> overflow;

  List<NavItem> get branches => [...primary, ...overflow];

  int branchIndexOf(String id) {
    final index = branches.indexWhere((item) => item.id == id);
    if (index < 0) {
      throw ArgumentError.value(id, 'id', 'Unknown navigation destination');
    }
    return index;
  }

  static RoleNavigationConfig forRole(UserRole role) {
    return switch (role) {
      UserRole.employee => employee,
      UserRole.driver => driver,
      UserRole.companyAdmin => companyAdmin,
      UserRole.driversAdmin => driversAdmin,
      UserRole.admin => admin,
    };
  }

  static const employee = RoleNavigationConfig(
    primary: [
      NavItem(
        id: NavIds.myTrips,
        icon: Icons.alt_route_outlined,
        labelKey: NavLabelKey.myTrips,
        route: AppRoutes.employeeHome,
      ),
      NavItem(
        id: NavIds.profile,
        icon: Icons.person_outline,
        labelKey: NavLabelKey.profile,
        route: AppRoutes.employeeProfile,
      ),
      NavItem(
        id: NavIds.settings,
        icon: Icons.settings_outlined,
        labelKey: NavLabelKey.settings,
        route: AppRoutes.employeeSettings,
      ),
    ],
    overflow: [],
  );

  static const driver = RoleNavigationConfig(
    primary: [
      NavItem(
        id: NavIds.attendance,
        icon: Icons.qr_code_scanner_outlined,
        labelKey: NavLabelKey.attendance,
        route: AppRoutes.driverHome,
      ),
      NavItem(
        id: NavIds.assignedTrips,
        icon: Icons.directions_car_outlined,
        labelKey: NavLabelKey.assignedTrips,
        route: AppRoutes.driverAssignedTrips,
      ),
      NavItem(
        id: NavIds.completedTrips,
        icon: Icons.task_alt_outlined,
        labelKey: NavLabelKey.completedTrips,
        route: AppRoutes.driverCompletedTrips,
      ),
      NavItem(
        id: NavIds.stats,
        icon: Icons.insights_outlined,
        labelKey: NavLabelKey.stats,
        route: AppRoutes.driverStats,
      ),
    ],
    overflow: [
      NavItem(
        id: NavIds.profile,
        icon: Icons.person_outline,
        labelKey: NavLabelKey.profile,
        route: AppRoutes.driverProfile,
      ),
      NavItem(
        id: NavIds.settings,
        icon: Icons.settings_outlined,
        labelKey: NavLabelKey.settings,
        route: AppRoutes.driverSettings,
      ),
    ],
  );

  static const companyAdmin = RoleNavigationConfig(
    primary: [
      NavItem(
        id: NavIds.requestedTrips,
        icon: Icons.inbox_outlined,
        labelKey: NavLabelKey.requestedTrips,
        route: AppRoutes.companyAdminHome,
      ),
      NavItem(
        id: NavIds.myTrips,
        icon: Icons.alt_route_outlined,
        labelKey: NavLabelKey.myTrips,
        route: AppRoutes.companyAdminMyTrips,
      ),
      NavItem(
        id: NavIds.trips,
        icon: Icons.directions_car_outlined,
        labelKey: NavLabelKey.trips,
        route: AppRoutes.companyAdminTrips,
      ),
      NavItem(
        id: NavIds.places,
        icon: Icons.place_outlined,
        labelKey: NavLabelKey.places,
        route: AppRoutes.companyAdminPlaces,
      ),
    ],
    overflow: [
      NavItem(
        id: NavIds.profile,
        icon: Icons.person_outline,
        labelKey: NavLabelKey.profile,
        route: AppRoutes.companyAdminProfile,
      ),
      NavItem(
        id: NavIds.settings,
        icon: Icons.settings_outlined,
        labelKey: NavLabelKey.settings,
        route: AppRoutes.companyAdminSettings,
      ),
    ],
  );

  static const driversAdmin = RoleNavigationConfig(
    primary: [
      NavItem(
        id: NavIds.requests,
        icon: Icons.inbox_outlined,
        labelKey: NavLabelKey.requests,
        route: AppRoutes.driversAdminHome,
      ),
      NavItem(
        id: NavIds.trips,
        icon: Icons.directions_car_outlined,
        labelKey: NavLabelKey.trips,
        route: AppRoutes.driversAdminTrips,
      ),
      NavItem(
        id: NavIds.attendanceBoard,
        icon: Icons.fact_check_outlined,
        labelKey: NavLabelKey.attendanceBoard,
        route: AppRoutes.driversAdminAttendance,
      ),
      NavItem(
        id: NavIds.drivers,
        icon: Icons.groups_outlined,
        labelKey: NavLabelKey.drivers,
        route: AppRoutes.driversAdminDrivers,
      ),
    ],
    overflow: [
      NavItem(
        id: NavIds.myTrips,
        icon: Icons.assignment_outlined,
        labelKey: NavLabelKey.myTrips,
        route: AppRoutes.driversAdminMyRequests,
      ),
      NavItem(
        id: NavIds.liveMap,
        icon: Icons.map_outlined,
        labelKey: NavLabelKey.liveMap,
        route: AppRoutes.driversAdminLiveMap,
      ),
      NavItem(
        id: NavIds.profile,
        icon: Icons.person_outline,
        labelKey: NavLabelKey.profile,
        route: AppRoutes.driversAdminProfile,
      ),
      NavItem(
        id: NavIds.settings,
        icon: Icons.settings_outlined,
        labelKey: NavLabelKey.settings,
        route: AppRoutes.driversAdminSettings,
      ),
    ],
  );

  static const admin = RoleNavigationConfig(
    primary: [
      NavItem(
        id: NavIds.dashboard,
        icon: Icons.dashboard_outlined,
        labelKey: NavLabelKey.dashboard,
        route: AppRoutes.adminDashboard,
      ),
      NavItem(
        id: NavIds.drivers,
        icon: Icons.local_taxi_outlined,
        labelKey: NavLabelKey.drivers,
        route: AppRoutes.adminDrivers,
      ),
      NavItem(
        id: NavIds.employees,
        icon: Icons.badge_outlined,
        labelKey: NavLabelKey.employees,
        route: AppRoutes.adminEmployees,
      ),
      NavItem(
        id: NavIds.places,
        icon: Icons.place_outlined,
        labelKey: NavLabelKey.places,
        route: AppRoutes.adminPlaces,
      ),
    ],
    overflow: [
      NavItem(
        id: NavIds.users,
        icon: Icons.manage_accounts_outlined,
        labelKey: NavLabelKey.users,
        route: AppRoutes.adminUsers,
      ),
      NavItem(
        id: NavIds.myTrips,
        icon: Icons.assignment_outlined,
        labelKey: NavLabelKey.myTrips,
        route: AppRoutes.adminMyTrips,
      ),
      NavItem(
        id: NavIds.profile,
        icon: Icons.person_outline,
        labelKey: NavLabelKey.profile,
        route: AppRoutes.adminProfile,
      ),
      NavItem(
        id: NavIds.settings,
        icon: Icons.settings_outlined,
        labelKey: NavLabelKey.settings,
        route: AppRoutes.adminSettings,
      ),
    ],
  );
}
