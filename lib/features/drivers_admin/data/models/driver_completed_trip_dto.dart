import 'package:equatable/equatable.dart';
import 'package:teletech_drivers/core/constants/api_json_keys.dart';
import 'package:teletech_drivers/core/network/api_json_parsers.dart';
import 'package:teletech_drivers/features/trip_request/data/mappers/trip_confirmation_status_mapper.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_confirmation_status.dart';

/// One `GET /drivers/{id}/trips` row.
final class DriverCompletedTripDto extends Equatable {
  const DriverCompletedTripDto({
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

  factory DriverCompletedTripDto.fromJson(Map<String, dynamic> json) {
    final confirmation = ApiJsonParsers.optionalString(
      json[ApiJsonKeys.confirmationStatus],
    );
    return DriverCompletedTripDto(
      id: ApiJsonParsers.requireNonEmptyString(json[ApiJsonKeys.id], 'trip id'),
      scheduledAt: ApiJsonParsers.requireDateTime(
        json[ApiJsonKeys.scheduledAt],
        'scheduled_at',
      ),
      goingStartedAt: ApiJsonParsers.optionalDateTime(
        json[ApiJsonKeys.goingStartedAt],
      ),
      finishedAt: ApiJsonParsers.optionalDateTime(json[ApiJsonKeys.finishedAt]),
      pickupSummary:
          ApiJsonParsers.optionalString(json[ApiJsonKeys.pickupSummary]) ?? '',
      destinationSummary:
          ApiJsonParsers.optionalString(json[ApiJsonKeys.destinationSummary]) ??
          '',
      durationSeconds: ApiJsonParsers.optionalInt(
        json[ApiJsonKeys.durationSeconds],
      ),
      distanceKm: ApiJsonParsers.optionalDouble(json[ApiJsonKeys.distanceKm]),
      confirmationStatus: confirmation == null
          ? null
          : TripConfirmationStatusMapper.fromApi(confirmation),
      driverShowedUp: ApiJsonParsers.optionalBool(
        json[ApiJsonKeys.driverShowedUp],
        ApiJsonKeys.driverShowedUp,
      ),
    );
  }

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
