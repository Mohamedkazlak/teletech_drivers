/// Relative paths under [AppConfig.apiBaseUrl] (no leading slash).
abstract final class ApiPaths {
  static const authLogin = 'auth/login';
  static const authRegister = 'auth/register';
  static const authLogout = 'auth/logout';
  static const authChangePassword = 'auth/change-password';
  static const authMe = 'auth/me';
  static const broadcastingAuth = 'broadcasting/auth';
  static const authMeStats = 'auth/me/stats';

  static const places = 'places';
  static String place(String id) => 'places/$id';

  static const drivers = 'drivers';
  static String driver(String id) => 'drivers/$id';
  static String driverStats(String id) => 'drivers/$id/stats';
  static String driverTrips(String id) => 'drivers/$id/trips';
  static String driverRestore(String id) => 'drivers/$id/restore';

  static const users = 'users';
  static String resetUserPassword(String id) => 'users/$id/reset-password';

  static const employees = 'employees';
  static String employee(String id) => 'employees/$id';
  static String employeeRestore(String id) => 'employees/$id/restore';

  static const tripRequests = 'trip-requests';
  static const tripRequestsMine = 'trip-requests/mine';
  static const tripRequestsApproveGroup = 'trip-requests/approve-group';
  static const tripRequestsGroupingSuggestions =
      'trip-requests/grouping-suggestions';
  static String tripRequest(String id) => 'trip-requests/$id';
  static String tripRequestCancel(String id) => 'trip-requests/$id/cancel';
  static String tripRequestApprove(String id) => 'trip-requests/$id/approve';
  static String tripRequestReject(String id) => 'trip-requests/$id/reject';
  static String tripRequestConfirm(String id) =>
      'trip-requests/$id/confirm-trip';

  static const trips = 'trips';
  static const myTrips = 'my-trips';
  static const tripsMine = 'trips/mine';
  static const tripsCreatedByMe = 'trips/created-by-me';
  static const tripsFromRequests = 'trips/from-requests';
  static String trip(String id) => 'trips/$id';
  static String tripAssign(String id) => 'trips/$id/assign';
  static String tripCancel(String id) => 'trips/$id/cancel';
  static String tripStart(String id) => 'trips/$id/start';
  static String tripArrive(String id) => 'trips/$id/arrive';
  static String tripStartReturn(String id) => 'trips/$id/start-return';
  static String tripEnd(String id) => 'trips/$id/end';
  static String tripReport(String id) => 'trips/$id/report';
  static String tripDriverRecommendations(String id) =>
      'trips/$id/driver-recommendations';

  static const attendanceCheckIn = 'attendance/check-in';
  static const attendanceCheckOut = 'attendance/check-out';
  static const attendanceToday = 'attendance/today';
  static const attendanceMe = 'attendance/me';
  static const attendance = 'attendance';
  static const attendanceTodaySummary = 'attendance/today/summary';
  static const attendanceQr = 'attendance/qr';
  static const attendanceAdjust = 'attendance/adjust';
  static String driverAttendance(String id) => 'drivers/$id/attendance';

  static const driverLocation = 'driver-location';
  static const driverLocationStop = 'driver-location/stop';
  static const liveMap = 'live-map';

  static const deviceTokens = 'device-tokens';

  static const notifications = 'notifications';
  static const notificationsUnreadCount = 'notifications/unread-count';
  static const notificationsReadAll = 'notifications/read-all';
  static String notificationRead(String id) => 'notifications/$id/read';
}
