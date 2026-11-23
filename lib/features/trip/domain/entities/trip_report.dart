import 'package:equatable/equatable.dart';
import 'package:teletech_drivers/features/tracking/domain/entities/route_point.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_status.dart';

/// View-model: derived trip report shown to Driver and Drivers Admin.
class TripReport extends Equatable {
  const TripReport({
    required this.status,
    required this.isInProgress,
    this.startedAt,
    this.finishedAt,
    this.totalDuration,
    this.goingDuration,
    this.waitingDuration,
    this.returnDuration,
    this.goingDistanceKm,
    this.returnDistanceKm,
    this.totalDistanceKm,
    this.goingPoints = const [],
    this.returnPoints = const [],
    this.startMarker,
    this.destinationMarker,
  });

  final TripStatus status;
  final bool isInProgress;

  final DateTime? startedAt;
  final DateTime? finishedAt;

  final Duration? totalDuration;
  final Duration? goingDuration;
  final Duration? waitingDuration;
  final Duration? returnDuration;

  final double? goingDistanceKm;
  final double? returnDistanceKm;
  final double? totalDistanceKm;

  final List<RoutePoint> goingPoints;
  final List<RoutePoint> returnPoints;
  final RoutePoint? startMarker;
  final RoutePoint? destinationMarker;

  bool get hasRouteGeometry =>
      goingPoints.isNotEmpty || returnPoints.isNotEmpty;

  @override
  List<Object?> get props => [
    status,
    isInProgress,
    startedAt,
    finishedAt,
    totalDuration,
    goingDuration,
    waitingDuration,
    returnDuration,
    goingDistanceKm,
    returnDistanceKm,
    totalDistanceKm,
    goingPoints,
    returnPoints,
    startMarker,
    destinationMarker,
  ];
}
