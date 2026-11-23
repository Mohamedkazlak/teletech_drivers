import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/features/notification/domain/entities/app_notification.dart';

/// Renders `title_key` / `body_key` with the name and place params.
String notificationTitle(
  AppLocalizations l10n,
  AppNotification notification,
  String languageCode,
) {
  return switch (notification.titleKey) {
    'notifications.request_submitted.title' =>
      l10n.notificationRequestSubmittedTitle,
    'notifications.trip_ready_to_assign.title' =>
      l10n.notificationTripReadyTitle,
    'notifications.trip_assigned.title' => l10n.notificationTripAssignedTitle,
    'notifications.own_trip_assigned.title' =>
      l10n.notificationOwnTripAssignedTitle,
    'notifications.trip_ended_report_needed.title' =>
      l10n.notificationTripEndedTitle,
    _ => l10n.notificationUnknown,
  };
}

/// Renders `body_key` with the name and place params.
String notificationBody(
  AppLocalizations l10n,
  AppNotification notification,
  String languageCode,
) {
  final names = _Names(notification.params, languageCode);
  return switch (notification.bodyKey) {
    'notifications.request_submitted.body' =>
      l10n.notificationRequestSubmittedBody(
        names.requester,
        names.pickup,
        names.destination,
      ),
    'notifications.trip_ready_to_assign.body' => l10n.notificationTripReadyBody(
      names.requester,
      names.pickup,
      names.destination,
    ),
    'notifications.trip_assigned.body' => l10n.notificationTripAssignedBody(
      names.driver,
      names.pickup,
      names.destination,
    ),
    'notifications.own_trip_assigned.body' =>
      l10n.notificationOwnTripAssignedBody(
        names.driver,
        names.pickup,
        names.destination,
      ),
    'notifications.trip_ended_report_needed.body' =>
      l10n.notificationTripEndedBody(names.pickup, names.destination),
    _ => l10n.notificationUnknown,
  };
}

final class _Names {
  _Names(this.params, this.languageCode);

  final Map<String, String> params;
  final String languageCode;

  String get requester => _name('requester_name');
  String get driver => _name('driver_name');
  String get pickup => params['pickup'] ?? '';
  String get destination => params['destination'] ?? '';

  String _name(String prefix) {
    final arabic = params['${prefix}_ar'] ?? '';
    final english = params['${prefix}_en'] ?? '';
    if (languageCode == 'ar' && arabic.isNotEmpty) return arabic;
    return english;
  }
}
