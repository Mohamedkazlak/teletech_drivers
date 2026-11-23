import 'package:teletech_drivers/core/router/app_routes.dart';
import 'package:teletech_drivers/features/auth/domain/entities/user_role.dart';
import 'package:teletech_drivers/features/notification/domain/entities/app_notification.dart';

/// Strategy: maps a notification onto the screen that should open.
String? notificationLocation({
  required UserRole role,
  required AppNotification notification,
}) {
  final requestId = _present(notification.tripRequestId);
  final tripId = _present(notification.tripId);
  return switch (notification.type) {
    AppNotificationType.tripEndedReportNeeded => _report(
      role,
      requestId,
      tripId,
    ),
    AppNotificationType.requestSubmitted =>
      requestId == null
          ? null
          : '${AppRoutes.companyAdminHome}?request=$requestId',
    AppNotificationType.tripReadyToAssign =>
      requestId == null
          ? null
          : '${AppRoutes.driversAdminHome}?request=$requestId',
    AppNotificationType.tripAssigned ||
    AppNotificationType.ownTripAssigned => _trip(role, tripId, requestId),
    AppNotificationType.unknown => null,
  };
}

String? _report(UserRole role, String? requestId, String? tripId) {
  final path = switch (role) {
    UserRole.employee when requestId != null =>
      AppRoutes.employeeTripRequestPath(requestId),
    UserRole.companyAdmin when requestId != null =>
      AppRoutes.companyAdminMyTripRequestPath(requestId),
    UserRole.driversAdmin when requestId != null =>
      AppRoutes.driversAdminMyRequestDetailsPath(requestId),
    UserRole.admin when requestId != null =>
      AppRoutes.adminMyRequestDetailsPath(requestId),
    UserRole.driver when tripId != null => AppRoutes.driverTripDetailsPath(
      tripId,
    ),
    _ => null,
  };
  if (path == null) return null;
  return '$path?report=1';
}

String? _trip(UserRole role, String? tripId, String? requestId) {
  if (tripId != null) {
    return switch (role) {
      UserRole.driver => AppRoutes.driverTripDetailsPath(tripId),
      UserRole.companyAdmin => AppRoutes.companyAdminTripDetailsPath(tripId),
      UserRole.driversAdmin => AppRoutes.driversAdminTripDetailsPath(tripId),
      UserRole.employee when requestId != null =>
        AppRoutes.employeeTripRequestPath(requestId),
      UserRole.admin when requestId != null =>
        AppRoutes.adminMyRequestDetailsPath(requestId),
      _ => null,
    };
  }
  if (requestId == null) return null;
  return switch (role) {
    UserRole.employee => AppRoutes.employeeTripRequestPath(requestId),
    UserRole.companyAdmin => AppRoutes.companyAdminMyTripRequestPath(requestId),
    UserRole.driversAdmin => AppRoutes.driversAdminMyRequestDetailsPath(
      requestId,
    ),
    UserRole.admin => AppRoutes.adminMyRequestDetailsPath(requestId),
    UserRole.driver => null,
  };
}

String? _present(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}
