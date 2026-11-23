import 'package:equatable/equatable.dart';
import 'package:teletech_drivers/features/tracking/domain/entities/route_point.dart';

/// A driving polyline with optional OSRM distance / duration metadata.
class DrivingRoute extends Equatable {
  const DrivingRoute({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
    this.isApproximate = false,
  });

  /// Factory: straight dashed-line fallback between two points.
  factory DrivingRoute.straight({
    required RoutePoint origin,
    required RoutePoint destination,
    required double distanceMeters,
  }) {
    return DrivingRoute(
      points: [origin, destination],
      distanceMeters: distanceMeters,
      durationSeconds: distanceMeters / 11.1, // ~40 km/h guess
      isApproximate: true,
    );
  }

  final List<RoutePoint> points;
  final double distanceMeters;
  final double durationSeconds;
  final bool isApproximate;

  bool get isUsable => points.length >= 2;

  @override
  List<Object?> get props =>
      [points, distanceMeters, durationSeconds, isApproximate];
}
