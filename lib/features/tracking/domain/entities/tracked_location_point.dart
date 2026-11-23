import 'package:equatable/equatable.dart';
import 'package:teletech_drivers/features/tracking/domain/entities/route_point.dart';

/// A GPS sample accepted by [LocationTrackingService] filtering.
class TrackedLocationPoint extends Equatable {
  const TrackedLocationPoint({
    required this.lat,
    required this.lng,
    required this.accuracyMeters,
    required this.speedMps,
    required this.headingDegrees,
    required this.timestamp,
  });

  final double lat;
  final double lng;
  final double accuracyMeters;
  final double speedMps;
  final double headingDegrees;
  final DateTime timestamp;

  RoutePoint get asRoutePoint => RoutePoint(lat, lng);

  @override
  List<Object?> get props => [
    lat,
    lng,
    accuracyMeters,
    speedMps,
    headingDegrees,
    timestamp,
  ];
}
