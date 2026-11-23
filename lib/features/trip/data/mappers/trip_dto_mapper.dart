import 'package:teletech_drivers/features/drivers_admin/data/mappers/driver_dto_mapper.dart';
import 'package:teletech_drivers/features/drivers_admin/domain/entities/driver_recommendation.dart';
import 'package:teletech_drivers/features/tracking/domain/entities/route_point.dart';
import 'package:teletech_drivers/features/tracking/domain/services/polyline_encoder.dart';
import 'package:teletech_drivers/features/trip/data/models/driver_recommendation_dto.dart';
import 'package:teletech_drivers/features/trip/data/models/trip_dto.dart';
import 'package:teletech_drivers/features/trip/data/models/trip_passenger_dto.dart';
import 'package:teletech_drivers/features/trip/data/models/trip_requester_dto.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_requester.dart';
import 'package:teletech_drivers/features/trip/data/models/trip_report_dto.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_report.dart';

/// Maps trip API DTOs onto domain types.
abstract final class TripDtoMapper {
  static const _maxRecommendedTier = 1;

  static Trip toEntity(TripDto dto) {
    final passengers = dto.passengers;
    return Trip(
      id: dto.id,
      driverId: dto.driverId,
      requestIds: [for (final passenger in passengers) passenger.requestId],
      passengerIds: [for (final passenger in passengers) passenger.employeeId],
      passengerNames: [for (final passenger in passengers) _name(passenger)],
      passengerBranches: [for (final passenger in passengers) passenger.branch],
      pickupSummary: dto.pickupSummary,
      destinationSummary: dto.destinationSummary,
      scheduledAt: dto.scheduledAt,
      status: dto.status,
      createdBy: dto.createdBy,
      createdAt: dto.createdAt,
      goingStartedAt: dto.goingStartedAt,
      goingEndedAt: dto.goingEndedAt,
      returnStartedAt: dto.returnStartedAt,
      finishedAt: dto.finishedAt,
      startLat: dto.startLat,
      startLng: dto.startLng,
      goingDistanceMeters: dto.goingDistanceM,
      returnDistanceMeters: dto.returnDistanceM,
      totalDistanceMeters: dto.totalDistanceM,
      goingRoute: dto.goingRoute,
      returnRoute: dto.returnRoute,
      confirmationStatus: dto.confirmationStatus,
      driverShowedUp: dto.driverShowedUp,
      requesters: _requesters(dto),
      passengerCount: dto.passengerCount,
      tracking: dto.tracking?.toEntity(),
    );
  }

  static List<TripRequester> _requesters(TripDto dto) {
    final rows = dto.requesters.isNotEmpty
        ? dto.requesters
        : [if (dto.requester != null) dto.requester!];
    return [for (final row in rows) _requester(row)];
  }

  static TripRequester _requester(TripRequesterDto dto) {
    return TripRequester(
      id: dto.id,
      nameEn: dto.nameEn,
      nameAr: dto.nameAr,
      phone: dto.phone,
      branch: dto.branch,
    );
  }

  static TripReport toReport(TripReportDto dto) {
    final goingPoints = _decode(dto.goingRoute);
    final returnPoints = _decode(dto.returnRoute);

    return TripReport(
      status: dto.status,
      isInProgress: dto.isInProgress,
      startedAt: dto.start,
      finishedAt: dto.finish,
      totalDuration: _seconds(dto.totalDurationSeconds),
      goingDuration: _seconds(dto.goingDurationSeconds),
      waitingDuration: _seconds(dto.waitingDurationSeconds),
      returnDuration: _seconds(dto.returnDurationSeconds),
      goingDistanceKm: dto.goingDistanceKm,
      returnDistanceKm: dto.returnDistanceKm,
      totalDistanceKm: dto.totalDistanceKm,
      goingPoints: goingPoints,
      returnPoints: returnPoints,
      startMarker: goingPoints.isEmpty ? null : goingPoints.first,
      destinationMarker: _destinationMarker(goingPoints, returnPoints),
    );
  }

  static DriverRecommendation toRecommendation(DriverRecommendationDto dto) {
    final isAvailable = !dto.isUnavailable;
    return DriverRecommendation(
      driver: DriverDtoMapper.toProfile(dto.driver),
      tier: dto.tier,
      isAvailable: isAvailable,
      hasScheduleConflict: dto.hasConflict,
      isOnActiveTrip: dto.isOnActiveTrip,
      favoriteMatch: dto.hasFavoriteMatch,
      tripsThisWeek: dto.tripsThisWeek,
      reasons: _reasons(
        isAvailable: isAvailable,
        hasConflict: dto.hasConflict,
        favoriteMatch: dto.hasFavoriteMatch,
        isOnActiveTrip: dto.isOnActiveTrip,
      ),
      isRecommended:
          dto.tier <= _maxRecommendedTier && isAvailable && !dto.hasConflict,
    );
  }

  static String _name(TripPassengerDto passenger) {
    return passenger.nameEn ?? passenger.nameAr ?? '';
  }

  static List<RoutePoint> _decode(String? encoded) {
    if (encoded == null || encoded.isEmpty) return const [];
    return PolylineEncoder.decode(encoded);
  }

  static Duration? _seconds(int? value) {
    if (value == null) return null;
    return Duration(seconds: value);
  }

  static RoutePoint? _destinationMarker(
    List<RoutePoint> goingPoints,
    List<RoutePoint> returnPoints,
  ) {
    if (goingPoints.isNotEmpty) return goingPoints.last;
    if (returnPoints.isNotEmpty) return returnPoints.first;
    return null;
  }

  static List<DriverRecommendationReason> _reasons({
    required bool isAvailable,
    required bool hasConflict,
    required bool favoriteMatch,
    required bool isOnActiveTrip,
  }) {
    return [
      if (favoriteMatch) DriverRecommendationReason.favoritePlace,
      if (isAvailable)
        DriverRecommendationReason.available
      else
        DriverRecommendationReason.unavailable,
      if (hasConflict) DriverRecommendationReason.scheduleConflict,
      if (isOnActiveTrip) DriverRecommendationReason.onActiveTrip,
    ];
  }
}
