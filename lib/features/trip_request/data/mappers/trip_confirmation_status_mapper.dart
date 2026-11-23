import 'package:teletech_drivers/features/trip_request/domain/entities/trip_confirmation_status.dart';

/// Maps Laravel `confirmation_status` strings.
abstract final class TripConfirmationStatusMapper {
  static TripConfirmationStatus fromApi(String value) {
    return switch (value.trim()) {
      'pending' => TripConfirmationStatus.pending,
      'confirmed' => TripConfirmationStatus.confirmed,
      'unconfirmed' => TripConfirmationStatus.unconfirmed,
      _ => throw FormatException('Unknown confirmation status: $value'),
    };
  }
}
