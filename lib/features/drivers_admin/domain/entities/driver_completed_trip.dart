import 'package:equatable/equatable.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_confirmation_status.dart';

/// One row from `GET /drivers/{id}/trips`.
class DriverCompletedTrip extends Equatable {
  const DriverCompletedTrip({
    required this.id,
    required this.scheduledAt,
    required this.pickupSummary,
    required this.destinationSummary,
    this.goingStartedAt,
    this.finishedAt,
    this.durationSeconds,
    this.distanceKm,
    this.confirmationStatus,
    this.driverShowedUp,
  });

  final String id;
  final DateTime scheduledAt;
  final DateTime? goingStartedAt;
  final DateTime? finishedAt;
  final String pickupSummary;
  final String destinationSummary;
  final int? durationSeconds;
  final double? distanceKm;
  final TripConfirmationStatus? confirmationStatus;
  final bool? driverShowedUp;

  @override
  List<Object?> get props => [
    id,
    scheduledAt,
    goingStartedAt,
    finishedAt,
    pickupSummary,
    destinationSummary,
    durationSeconds,
    distanceKm,
    confirmationStatus,
    driverShowedUp,
  ];
}
