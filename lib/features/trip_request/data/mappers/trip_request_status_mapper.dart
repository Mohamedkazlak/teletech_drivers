import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request_status.dart';

/// Maps Laravel trip-request status strings ↔ [TripRequestStatus].
abstract final class TripRequestStatusMapper {
  static TripRequestStatus fromApi(String value) {
    return switch (value.trim()) {
      'pending' => TripRequestStatus.pending,
      'approved' => TripRequestStatus.approved,
      'rejected' => TripRequestStatus.rejected,
      'cancelled' => TripRequestStatus.cancelled,
      _ => throw FormatException('Unknown trip request status: $value'),
    };
  }

  static String toApi(TripRequestStatus status) {
    return switch (status) {
      TripRequestStatus.pending => 'pending',
      TripRequestStatus.approved => 'approved',
      TripRequestStatus.rejected => 'rejected',
      TripRequestStatus.cancelled => 'cancelled',
    };
  }
}
