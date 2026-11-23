import 'package:teletech_drivers/features/trip/domain/entities/trip_status.dart';

/// Maps Laravel trip status strings ↔ [TripStatus].
abstract final class TripStatusMapper {
  static const atDestinationApi = 'at_destination';

  static TripStatus fromApi(String value) {
    return switch (value.trim()) {
      'unassigned' => TripStatus.unassigned,
      'assigned' => TripStatus.assigned,
      'going' => TripStatus.going,
      atDestinationApi => TripStatus.atDestination,
      'returning' => TripStatus.returning,
      'completed' => TripStatus.completed,
      'cancelled' => TripStatus.cancelled,
      // Older payloads used this value for an in-progress outbound leg.
      'started' => TripStatus.going,
      _ => throw FormatException('Unknown trip status: $value'),
    };
  }

  static String toApi(TripStatus status) {
    return switch (status) {
      TripStatus.unassigned => 'unassigned',
      TripStatus.assigned => 'assigned',
      TripStatus.going => 'going',
      TripStatus.atDestination => atDestinationApi,
      TripStatus.returning => 'returning',
      TripStatus.completed => 'completed',
      TripStatus.cancelled => 'cancelled',
    };
  }
}
