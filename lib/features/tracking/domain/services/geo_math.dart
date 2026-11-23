import 'dart:math' as math;

import 'package:teletech_drivers/features/tracking/domain/entities/route_point.dart';

/// Pure-Dart geospatial helpers.
abstract final class GeoMath {
  static const _earthRadiusMeters = 6371000.0;

  static double distanceMeters(RoutePoint a, RoutePoint b) {
    final dLat = _toRad(b.lat - a.lat);
    final dLng = _toRad(b.lng - a.lng);
    final lat1 = _toRad(a.lat);
    final lat2 = _toRad(b.lat);
    final h =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) * math.cos(lat2) * math.sin(dLng / 2) * math.sin(dLng / 2);
    return 2 * _earthRadiusMeters * math.asin(math.sqrt(h));
  }

  /// Initial bearing in degrees [0, 360).
  static double bearingDegrees(RoutePoint from, RoutePoint to) {
    final lat1 = _toRad(from.lat);
    final lat2 = _toRad(to.lat);
    final dLng = _toRad(to.lng - from.lng);
    final y = math.sin(dLng) * math.cos(lat2);
    final x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
    return (_toDeg(math.atan2(y, x)) + 360) % 360;
  }

  static RoutePoint interpolate(RoutePoint a, RoutePoint b, double t) {
    final clamped = t.clamp(0.0, 1.0);
    return RoutePoint(
      a.lat + (b.lat - a.lat) * clamped,
      a.lng + (b.lng - a.lng) * clamped,
    );
  }

  /// Projects [point] onto segment [a]→[b]. Returns (projected, t in [0,1]).
  static (RoutePoint point, double t) projectOnSegment(
    RoutePoint point,
    RoutePoint a,
    RoutePoint b,
  ) {
    final abLat = b.lat - a.lat;
    final abLng = b.lng - a.lng;
    final abLen2 = abLat * abLat + abLng * abLng;
    if (abLen2 == 0) return (a, 0);
    final t =
        ((point.lat - a.lat) * abLat + (point.lng - a.lng) * abLng) / abLen2;
    final clamped = t.clamp(0.0, 1.0);
    return (interpolate(a, b, clamped), clamped);
  }

  static double _toRad(double degrees) => degrees * math.pi / 180;
  static double _toDeg(double radians) => radians * 180 / math.pi;
}
