import 'package:equatable/equatable.dart';

/// Lifecycle event stored on a notification row.
enum AppNotificationType {
  requestSubmitted,
  tripReadyToAssign,
  tripAssigned,
  ownTripAssigned,
  tripEndedReportNeeded,
  unknown;

  static AppNotificationType fromWire(String raw) {
    return switch (raw) {
      'request_submitted' => AppNotificationType.requestSubmitted,
      'trip_ready_to_assign' => AppNotificationType.tripReadyToAssign,
      'trip_assigned' => AppNotificationType.tripAssigned,
      'own_trip_assigned' => AppNotificationType.ownTripAssigned,
      'trip_ended_report_needed' => AppNotificationType.tripEndedReportNeeded,
      _ => AppNotificationType.unknown,
    };
  }

  String get wireValue {
    return switch (this) {
      AppNotificationType.requestSubmitted => 'request_submitted',
      AppNotificationType.tripReadyToAssign => 'trip_ready_to_assign',
      AppNotificationType.tripAssigned => 'trip_assigned',
      AppNotificationType.ownTripAssigned => 'own_trip_assigned',
      AppNotificationType.tripEndedReportNeeded => 'trip_ended_report_needed',
      AppNotificationType.unknown => '',
    };
  }
}

/// One in-app notification. Copy is rendered from [titleKey] and [bodyKey].
final class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.type,
    required this.titleKey,
    required this.bodyKey,
    required this.params,
    required this.createdAt,
    this.tripRequestId,
    this.tripId,
    this.readAt,
  });

  final String id;
  final AppNotificationType type;
  final String titleKey;
  final String bodyKey;
  final Map<String, String> params;
  final DateTime createdAt;
  final String? tripRequestId;
  final String? tripId;
  final DateTime? readAt;

  bool get isUnread => readAt == null;

  @override
  List<Object?> get props => [
    id,
    type,
    titleKey,
    bodyKey,
    params,
    createdAt,
    tripRequestId,
    tripId,
    readAt,
  ];
}
