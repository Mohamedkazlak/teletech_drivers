import 'package:latlong2/latlong.dart';

/// Result of a driving-route request (OSRM or fallback).
class RoutingResult {
  const RoutingResult({
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;
}

/// Interface: Strategy for fetching a driving polyline between two points.
abstract interface class RoutingService {
  /// Returns null when the upstream router fails or is disabled.
  Future<RoutingResult?> route({
    required LatLng start,
    required LatLng end,
  });
}
