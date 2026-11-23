import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:teletech_drivers/core/navigation/role_navigation_config.dart';
import 'package:teletech_drivers/core/presentation/role_shell.dart';
import 'package:teletech_drivers/core/router/app_routes.dart';
import 'package:teletech_drivers/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:teletech_drivers/features/admin/presentation/screens/admin_drivers_screen.dart';
import 'package:teletech_drivers/features/admin/presentation/screens/admin_employees_screen.dart';
import 'package:teletech_drivers/features/admin/presentation/screens/admin_my_trips_screen.dart';
import 'package:teletech_drivers/features/admin/presentation/screens/admin_places_screen.dart';
import 'package:teletech_drivers/features/admin/presentation/screens/admin_users_screen.dart';
import 'package:teletech_drivers/features/auth/presentation/screens/profile_screen.dart';
import 'package:teletech_drivers/features/auth/presentation/screens/settings_screen.dart';
import 'package:teletech_drivers/features/attendance/presentation/screens/attendance_qr_screen.dart';
import 'package:teletech_drivers/features/attendance/presentation/screens/attendance_today_screen.dart';
import 'package:teletech_drivers/features/company_admin/presentation/screens/company_admin_home_screen.dart';
import 'package:teletech_drivers/features/company_admin/presentation/screens/company_admin_my_trips_screen.dart';
import 'package:teletech_drivers/features/company_admin/presentation/screens/company_admin_my_requests_screen.dart';
import 'package:teletech_drivers/features/company_admin/presentation/screens/company_admin_places_screen.dart';
import 'package:teletech_drivers/features/company_admin/presentation/screens/company_admin_request_details_screen.dart';
import 'package:teletech_drivers/features/company_admin/presentation/screens/company_admin_trips_screen.dart';
import 'package:teletech_drivers/features/company_admin/presentation/screens/my_request_progress_details_screen.dart';
import 'package:teletech_drivers/features/company_admin/presentation/screens/trip_details_screen.dart';
import 'package:teletech_drivers/features/driver/presentation/screens/driver_assigned_trips_screen.dart';
import 'package:teletech_drivers/features/driver/presentation/screens/driver_completed_trips_screen.dart';
import 'package:teletech_drivers/features/driver/presentation/screens/driver_home_screen.dart';
import 'package:teletech_drivers/features/driver_stats/presentation/screens/driver_stats_screen.dart';
import 'package:teletech_drivers/features/driver/presentation/screens/driver_trip_details_screen.dart';
import 'package:teletech_drivers/features/drivers_admin/presentation/screens/driver_details_screen.dart';
import 'package:teletech_drivers/features/drivers_admin/presentation/screens/drivers_admin_drivers_screen.dart';
import 'package:teletech_drivers/features/drivers_admin/presentation/screens/drivers_admin_home_screen.dart';
import 'package:teletech_drivers/features/drivers_admin/presentation/screens/drivers_admin_my_requests_screen.dart';
import 'package:teletech_drivers/features/drivers_admin/presentation/screens/drivers_admin_request_details_screen.dart';
import 'package:teletech_drivers/features/drivers_admin/presentation/screens/drivers_admin_shell.dart';
import 'package:teletech_drivers/features/drivers_admin/presentation/screens/drivers_admin_trip_details_screen.dart';
import 'package:teletech_drivers/features/drivers_admin/presentation/screens/drivers_admin_trips_screen.dart';
import 'package:teletech_drivers/features/employee/presentation/screens/employee_home_screen.dart';
import 'package:teletech_drivers/features/notification/presentation/screens/notifications_screen.dart';
import 'package:teletech_drivers/features/trip_request/presentation/screens/trip_request_details_screen.dart';
import 'package:teletech_drivers/features/tracking/presentation/screens/admin_live_map_screen.dart';
import 'package:teletech_drivers/features/tracking/presentation/screens/driver_live_map_screen.dart';
import 'package:teletech_drivers/features/trip_request/presentation/screens/new_trip_request_screen.dart';

/// Role shells plus full-screen routes that stay on [rootNavigatorKey]
/// so the glass bar is not visible.
List<RouteBase> buildRoleShellRoutes(
  GlobalKey<NavigatorState> rootNavigatorKey,
) {
  return [
    _shell(
      rootNavigatorKey: rootNavigatorKey,
      config: RoleNavigationConfig.employee,
      branches: [
        _branch(
          GoRoute(
            path: AppRoutes.employeeHome,
            name: 'employeeHome',
            builder: (context, state) => const EmployeeHomeScreen(),
            routes: [
              GoRoute(
                path: 'requests/:requestId',
                name: 'employeeTripRequestDetails',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) {
                  final requestId = state.pathParameters['requestId'] ?? '';
                  return TripRequestDetailsScreen(requestId: requestId);
                },
              ),
            ],
          ),
        ),
        _branch(_profile(AppRoutes.employeeProfile, 'employeeProfile')),
        _branch(_settings(AppRoutes.employeeSettings, 'employeeSettings')),
      ],
    ),
    _rootPage(
      rootNavigatorKey,
      path: AppRoutes.employeeNewRequest,
      name: 'employeeNewRequest',
      child: const NewTripRequestScreen(),
    ),
    _rootPage(
      rootNavigatorKey,
      path: AppRoutes.employeeNotifications,
      name: 'employeeNotifications',
      child: const NotificationsScreen(),
    ),
    _shell(
      rootNavigatorKey: rootNavigatorKey,
      config: RoleNavigationConfig.driver,
      branches: [
        _branch(
          GoRoute(
            path: AppRoutes.driverHome,
            name: 'driverHome',
            builder: (context, state) => const DriverHomeScreen(),
          ),
        ),
        _branch(
          GoRoute(
            path: AppRoutes.driverAssignedTrips,
            name: 'driverAssignedTrips',
            builder: (context, state) => const DriverAssignedTripsScreen(),
          ),
        ),
        _branch(
          GoRoute(
            path: AppRoutes.driverCompletedTrips,
            name: 'driverCompletedTrips',
            builder: (context, state) => const DriverCompletedTripsScreen(),
          ),
        ),
        _branch(
          GoRoute(
            path: AppRoutes.driverStats,
            name: 'driverStats',
            builder: (context, state) => const DriverStatsScreen(),
          ),
        ),
        _branch(_profile(AppRoutes.driverProfile, 'driverProfile')),
        _branch(_settings(AppRoutes.driverSettings, 'driverSettings')),
      ],
    ),
    _rootPage(
      rootNavigatorKey,
      path: AppRoutes.driverNotifications,
      name: 'driverNotifications',
      child: const NotificationsScreen(),
    ),
    GoRoute(
      path: '/driver/trips/:tripId',
      name: 'driverTripDetails',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final tripId = state.pathParameters['tripId'] ?? '';
        return DriverTripDetailsScreen(tripId: tripId);
      },
    ),
    GoRoute(
      path: '/driver/trips/:tripId/live-map',
      name: 'driverLiveMap',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) {
        final tripId = state.pathParameters['tripId'] ?? '';
        return DriverLiveMapScreen(tripId: tripId);
      },
    ),
    _shell(
      rootNavigatorKey: rootNavigatorKey,
      config: RoleNavigationConfig.companyAdmin,
      branches: [
        _branch(
          GoRoute(
            path: AppRoutes.companyAdminHome,
            name: 'companyAdminHome',
            builder: (context, state) => const CompanyAdminHomeScreen(),
            routes: [
              GoRoute(
                path: 'requests/:requestId',
                name: 'companyAdminRequestDetails',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) {
                  final requestId = state.pathParameters['requestId'] ?? '';
                  return CompanyAdminRequestDetailsScreen(requestId: requestId);
                },
              ),
            ],
          ),
        ),
        _branch(
          GoRoute(
            path: AppRoutes.companyAdminMyTrips,
            name: 'companyAdminMyTrips',
            builder: (context, state) => const CompanyAdminMyTripsScreen(),
            routes: [
              GoRoute(
                path: ':requestId',
                name: 'companyAdminMyTripRequest',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) {
                  final requestId = state.pathParameters['requestId'] ?? '';
                  return TripRequestDetailsScreen(requestId: requestId);
                },
              ),
            ],
          ),
        ),
        _branch(
          GoRoute(
            path: AppRoutes.companyAdminTrips,
            name: 'companyAdminTrips',
            builder: (context, state) => const CompanyAdminTripsScreen(),
            routes: [
              GoRoute(
                path: ':tripId',
                name: 'companyAdminTripDetails',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) {
                  final tripId = state.pathParameters['tripId'] ?? '';
                  return TripDetailsScreen(tripId: tripId);
                },
              ),
            ],
          ),
        ),
        _branch(
          GoRoute(
            path: AppRoutes.companyAdminPlaces,
            name: 'companyAdminPlaces',
            builder: (context, state) => const CompanyAdminPlacesScreen(),
          ),
        ),
        _branch(_profile(AppRoutes.companyAdminProfile, 'companyAdminProfile')),
        _branch(
          _settings(AppRoutes.companyAdminSettings, 'companyAdminSettings'),
        ),
      ],
    ),
    _rootPage(
      rootNavigatorKey,
      path: AppRoutes.companyAdminNewRequest,
      name: 'companyAdminNewRequest',
      child: const NewTripRequestScreen(),
    ),
    _rootPage(
      rootNavigatorKey,
      path: AppRoutes.companyAdminNotifications,
      name: 'companyAdminNotifications',
      child: const NotificationsScreen(),
    ),
    GoRoute(
      path: AppRoutes.companyAdminMyRequests,
      name: 'companyAdminMyRequests',
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state) => const CompanyAdminMyRequestsScreen(),
      routes: [
        GoRoute(
          path: ':requestId',
          name: 'companyAdminMyRequestDetails',
          parentNavigatorKey: rootNavigatorKey,
          builder: (context, state) {
            final requestId = state.pathParameters['requestId'] ?? '';
            return MyRequestProgressDetailsScreen(requestId: requestId);
          },
        ),
      ],
    ),
    _shell(
      rootNavigatorKey: rootNavigatorKey,
      config: RoleNavigationConfig.driversAdmin,
      shell: (context, state, navigationShell) {
        return DriversAdminShell(navigationShell: navigationShell);
      },
      branches: [
        _branch(
          GoRoute(
            path: AppRoutes.driversAdminHome,
            name: 'driversAdminHome',
            builder: (context, state) => const DriversAdminHomeScreen(),
            routes: [
              GoRoute(
                path: 'requests/:requestId',
                name: 'driversAdminRequestDetails',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) {
                  final requestId = state.pathParameters['requestId'] ?? '';
                  return DriversAdminRequestDetailsScreen(requestId: requestId);
                },
              ),
            ],
          ),
        ),
        _branch(
          GoRoute(
            path: AppRoutes.driversAdminTrips,
            name: 'driversAdminTrips',
            builder: (context, state) => const DriversAdminTripsScreen(),
            routes: [
              GoRoute(
                path: ':tripId',
                name: 'driversAdminTripDetails',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) {
                  final tripId = state.pathParameters['tripId'] ?? '';
                  final openAssign = state.uri.queryParameters['assign'] == '1';
                  return DriversAdminTripDetailsScreen(
                    tripId: tripId,
                    openAssignOnLoad: openAssign,
                  );
                },
              ),
            ],
          ),
        ),
        _branch(
          GoRoute(
            path: AppRoutes.driversAdminAttendance,
            name: 'driversAdminAttendance',
            builder: (context, state) => const AttendanceTodayScreen(),
            routes: [
              GoRoute(
                path: 'qr',
                name: 'driversAdminAttendanceQr',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) => const AttendanceQrScreen(),
              ),
            ],
          ),
        ),
        _branch(
          GoRoute(
            path: AppRoutes.driversAdminDrivers,
            name: 'driversAdminDrivers',
            builder: (context, state) => const DriversAdminDriversScreen(),
            routes: [
              GoRoute(
                path: ':driverId',
                name: 'driversAdminDriverDetails',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) {
                  final driverId = state.pathParameters['driverId'] ?? '';
                  return DriverDetailsScreen(driverId: driverId);
                },
              ),
            ],
          ),
        ),
        _branch(
          GoRoute(
            path: AppRoutes.driversAdminMyRequests,
            name: 'driversAdminMyRequests',
            builder: (context, state) => const DriversAdminMyRequestsScreen(),
            routes: [
              GoRoute(
                path: ':requestId',
                name: 'driversAdminMyRequestDetails',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) {
                  final requestId = state.pathParameters['requestId'] ?? '';
                  return MyRequestProgressDetailsScreen(requestId: requestId);
                },
              ),
            ],
          ),
        ),
        _branch(
          GoRoute(
            path: AppRoutes.driversAdminLiveMap,
            name: 'driversAdminLiveMap',
            builder: (context, state) {
              final driverId = state.uri.queryParameters['driverId'];
              return AdminLiveMapScreen(
                focusDriverId: driverId,
                showBackButton: false,
              );
            },
          ),
        ),
        _branch(_profile(AppRoutes.driversAdminProfile, 'driversAdminProfile')),
        _branch(
          _settings(AppRoutes.driversAdminSettings, 'driversAdminSettings'),
        ),
      ],
    ),
    _rootPage(
      rootNavigatorKey,
      path: AppRoutes.driversAdminNewRequest,
      name: 'driversAdminNewRequest',
      child: const NewTripRequestScreen(),
    ),
    _rootPage(
      rootNavigatorKey,
      path: AppRoutes.driversAdminNotifications,
      name: 'driversAdminNotifications',
      child: const NotificationsScreen(),
    ),
    _shell(
      rootNavigatorKey: rootNavigatorKey,
      config: RoleNavigationConfig.admin,
      branches: [
        _branch(
          GoRoute(
            path: AppRoutes.adminDashboard,
            name: 'adminDashboard',
            builder: (context, state) => const AdminDashboardScreen(),
          ),
        ),
        _branch(
          GoRoute(
            path: AppRoutes.adminDrivers,
            name: 'adminDrivers',
            builder: (context, state) => const AdminDriversScreen(),
            routes: [
              GoRoute(
                path: ':driverId',
                name: 'adminDriverDetails',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) {
                  final driverId = state.pathParameters['driverId'] ?? '';
                  return DriverDetailsScreen(driverId: driverId);
                },
              ),
            ],
          ),
        ),
        _branch(
          GoRoute(
            path: AppRoutes.adminEmployees,
            name: 'adminEmployees',
            builder: (context, state) => const AdminEmployeesScreen(),
          ),
        ),
        _branch(
          GoRoute(
            path: AppRoutes.adminPlaces,
            name: 'adminPlaces',
            builder: (context, state) => const AdminPlacesScreen(),
          ),
        ),
        _branch(
          GoRoute(
            path: AppRoutes.adminUsers,
            name: 'adminUsers',
            builder: (context, state) => const AdminUsersScreen(),
          ),
        ),
        _branch(
          GoRoute(
            path: AppRoutes.adminMyTrips,
            name: 'adminMyTrips',
            builder: (context, state) => const AdminMyTripsScreen(),
            routes: [
              GoRoute(
                path: ':requestId',
                name: 'adminMyRequestDetails',
                parentNavigatorKey: rootNavigatorKey,
                builder: (context, state) {
                  final requestId = state.pathParameters['requestId'] ?? '';
                  return MyRequestProgressDetailsScreen(requestId: requestId);
                },
              ),
            ],
          ),
        ),
        _branch(_profile(AppRoutes.adminProfile, 'adminProfile')),
        _branch(_settings(AppRoutes.adminSettings, 'adminSettings')),
      ],
    ),
    _rootPage(
      rootNavigatorKey,
      path: AppRoutes.adminNewRequest,
      name: 'adminNewRequest',
      child: const NewTripRequestScreen(),
    ),
    _rootPage(
      rootNavigatorKey,
      path: AppRoutes.adminNotifications,
      name: 'adminNotifications',
      child: const NotificationsScreen(),
    ),
  ];
}

StatefulShellRoute _shell({
  required GlobalKey<NavigatorState> rootNavigatorKey,
  required RoleNavigationConfig config,
  required List<StatefulShellBranch> branches,
  StatefulShellRouteBuilder? shell,
}) {
  return StatefulShellRoute.indexedStack(
    parentNavigatorKey: rootNavigatorKey,
    builder:
        shell ??
        (context, state, navigationShell) {
          return RoleShell(navigationShell: navigationShell, config: config);
        },
    branches: branches,
  );
}

StatefulShellBranch _branch(GoRoute route) {
  return StatefulShellBranch(routes: [route]);
}

GoRoute _profile(String path, String name) {
  return GoRoute(
    path: path,
    name: name,
    builder: (context, state) => const ProfileScreen(),
  );
}

GoRoute _settings(String path, String name) {
  return GoRoute(
    path: path,
    name: name,
    builder: (context, state) => const SettingsScreen(),
  );
}

GoRoute _rootPage(
  GlobalKey<NavigatorState> rootNavigatorKey, {
  required String path,
  required String name,
  required Widget child,
}) {
  return GoRoute(
    path: path,
    name: name,
    parentNavigatorKey: rootNavigatorKey,
    builder: (context, state) => child,
  );
}
