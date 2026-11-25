import 'package:teletech_drivers/features/auth/domain/entities/user_role.dart';

/// Application route paths.
abstract final class AppRoutes {
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String completeProfile = '/complete-profile';
  static const String onboarding = '/onboarding';
  static const String changePasswordRequired = '/change-password';
  static const String companyAdminHome = '/company-admin';
  static const String driversAdminHome = '/drivers-admin';
  static const String driverHome = '/driver';
  static const String employeeHome = '/employee';
  static const String adminDashboard = '/admin/dashboard';
  static const String adminDrivers = '/admin/drivers';
  static const String adminPlaces = '/admin/places';
  static const String adminEmployees = '/admin/employees';
  static const String adminUsers = '/admin/users';
  static const String adminMyTrips = '/admin/my-trips';

  static const String employeeProfile = '/employee/profile';
  static const String employeeSettings = '/employee/settings';
  static const String employeeNewRequest = '/employee/new-request';
  static const String employeeNotifications = '/employee/notifications';

  static String employeeTripRequestPath(String requestId) =>
      '/employee/requests/$requestId';

  static String companyAdminMyTripRequestPath(String requestId) =>
      '/company-admin/my-trips/$requestId';

  static const String driverProfile = '/driver/profile';
  static const String driverSettings = '/driver/settings';
  static const String driverAssignedTrips = '/driver/assigned-trips';
  static const String driverCompletedTrips = '/driver/completed-trips';
  static const String driverStats = '/driver/stats';

  static const String companyAdminMyTrips = '/company-admin/my-trips';
  static const String companyAdminTrips = '/company-admin/trips';
  static const String companyAdminPlaces = '/company-admin/places';
  static const String companyAdminMyRequests = '/company-admin/my-requests';
  static const String companyAdminProfile = '/company-admin/profile';
  static const String companyAdminSettings = '/company-admin/settings';
  static const String companyAdminNewRequest = '/company-admin/new-request';
  static const String companyAdminNotifications =
      '/company-admin/notifications';

  static const String driversAdminTrips = '/drivers-admin/trips';
  static const String driversAdminDrivers = '/drivers-admin/drivers';
  static const String driversAdminMyRequests = '/drivers-admin/my-requests';
  static const String driversAdminProfile = '/drivers-admin/profile';
  static const String driversAdminSettings = '/drivers-admin/settings';
  static const String driversAdminNewRequest = '/drivers-admin/new-request';
  static const String driversAdminNotifications =
      '/drivers-admin/notifications';

  static const String adminProfile = '/admin/profile';
  static const String adminSettings = '/admin/settings';
  static const String adminNewRequest = '/admin/new-request';
  static const String adminNotifications = '/admin/notifications';
  static const String driverNotifications = '/driver/notifications';

  static String notificationsPath(UserRole role) {
    return switch (role) {
      UserRole.employee => employeeNotifications,
      UserRole.companyAdmin => companyAdminNotifications,
      UserRole.driversAdmin => driversAdminNotifications,
      UserRole.admin => adminNotifications,
      UserRole.driver => driverNotifications,
    };
  }

  /// Full-screen create-request route for [role], opened on the root navigator.
  static String newTripRequestPath(UserRole role) {
    return switch (role) {
      UserRole.employee => employeeNewRequest,
      UserRole.companyAdmin => companyAdminNewRequest,
      UserRole.driversAdmin => driversAdminNewRequest,
      UserRole.admin => adminNewRequest,
      UserRole.driver => driverHome,
    };
  }

  static String adminDriverDetailsPath(String driverId) =>
      '/admin/drivers/$driverId';

  static String adminMyRequestDetailsPath(String requestId) =>
      '/admin/my-trips/$requestId';

  static String companyAdminTripDetailsPath(String tripId) =>
      '/company-admin/trips/$tripId';

  static String companyAdminRequestDetailsPath(String requestId) =>
      '/company-admin/requests/$requestId';

  static String companyAdminMyRequestDetailsPath(String requestId) =>
      '/company-admin/my-requests/$requestId';

  static String driversAdminTripDetailsPath(String tripId) =>
      '/drivers-admin/trips/$tripId';

  /// Trip details with assign-driver sheet opened on load.
  static String driversAdminTripAssignPath(String tripId) =>
      '/drivers-admin/trips/$tripId?assign=1';

  static String driversAdminRequestDetailsPath(String requestId) =>
      '/drivers-admin/requests/$requestId';

  static String driversAdminMyRequestDetailsPath(String requestId) =>
      '/drivers-admin/my-requests/$requestId';

  static String driversAdminDriverDetailsPath(String driverId) =>
      '/drivers-admin/drivers/$driverId';

  static const String driversAdminLiveMap = '/drivers-admin/live-map';

  static const String driversAdminAttendance = '/drivers-admin/attendance';

  static const String driversAdminAttendanceQr = '/drivers-admin/attendance/qr';

  static String driverTripDetailsPath(String tripId) => '/driver/trips/$tripId';

  static String driverLiveMapPath(String tripId) =>
      '/driver/trips/$tripId/live-map';

  static String driversAdminLiveMapPath({String? driverId}) {
    if (driverId == null || driverId.isEmpty) {
      return driversAdminLiveMap;
    }
    return '$driversAdminLiveMap?driverId=$driverId';
  }
}
