import 'package:equatable/equatable.dart';
import 'package:teletech_drivers/features/tracking/domain/entities/route_point.dart';

/// Progress along a trip leg, computed by [TripProgressCalculator].
class TripProgress extends Equatable {
  const TripProgress({
    required this.distanceCoveredMeters,
    required this.distanceRemainingMeters,
    required this.percentComplete,
    required this.snappedPoint,
    required this.segmentIndex,
    this.etaSeconds,
    this.distanceToRouteMeters = 0,
    this.arrived = false,
  });

  final double distanceCoveredMeters;
  final double distanceRemainingMeters;
  final double percentComplete;
  final double? etaSeconds;
  final RoutePoint snappedPoint;
  final int segmentIndex;
  final double distanceToRouteMeters;
  final bool arrived;

  @override
  List<Object?> get props => [
    distanceCoveredMeters,
    distanceRemainingMeters,
    percentComplete,
    etaSeconds,
    snappedPoint,
    segmentIndex,
    distanceToRouteMeters,
    arrived,
  ];
}
