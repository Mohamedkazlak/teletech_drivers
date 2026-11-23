import 'package:teletech_drivers/features/tracking/domain/entities/route_point.dart';
import 'package:teletech_drivers/features/tracking/domain/entities/trip_progress.dart';
import 'package:teletech_drivers/features/tracking/domain/services/geo_math.dart';

/// Pure Dart progress along a polyline.
///
/// Percent is monotonic so GPS jitter cannot move progress backwards.
class TripProgressCalculator {
  TripProgressCalculator({this.arrivalRadiusMeters = 100});

  final double arrivalRadiusMeters;

  double _maxPercent = 0;
  double? _initialStraightDistance;

  void reset() {
    _maxPercent = 0;
    _initialStraightDistance = null;
  }

  /// Snaps [position] to [polyline] and returns covered / remaining / ETA.
  TripProgress calculate({
    required List<RoutePoint> polyline,
    required RoutePoint position,
    required RoutePoint target,
    double? routeDurationSeconds,
    double? recentSpeedMetersPerSecond,
    bool straightLineFallback = false,
  }) {
    if (polyline.length < 2) {
      return _straightProgress(
        position: position,
        target: target,
        recentSpeedMetersPerSecond: recentSpeedMetersPerSecond,
      );
    }

    if (straightLineFallback) {
      return _straightProgress(
        position: position,
        target: target,
        recentSpeedMetersPerSecond: recentSpeedMetersPerSecond,
      );
    }

    final snap = _snapToPolyline(polyline, position);
    final total = _polylineLength(polyline);
    final covered = snap.distanceAlongMeters.clamp(0.0, total);
    final remaining = (total - covered).clamp(0.0, total);
    var percent = total <= 0 ? 1.0 : (covered / total).clamp(0.0, 1.0);
    if (percent < _maxPercent) {
      percent = _maxPercent;
    } else {
      _maxPercent = percent;
    }

    final distanceToTarget = GeoMath.distanceMeters(position, target);
    final arrived = distanceToTarget <= arrivalRadiusMeters;

    final eta = _etaSeconds(
      remainingMeters: remaining,
      routeDurationSeconds: routeDurationSeconds,
      percentComplete: percent,
      recentSpeedMetersPerSecond: recentSpeedMetersPerSecond,
    );

    return TripProgress(
      distanceCoveredMeters: covered,
      distanceRemainingMeters: remaining,
      percentComplete: percent,
      etaSeconds: eta,
      snappedPoint: snap.point,
      segmentIndex: snap.segmentIndex,
      distanceToRouteMeters: snap.distanceToRouteMeters,
      arrived: arrived,
    );
  }

  TripProgress _straightProgress({
    required RoutePoint position,
    required RoutePoint target,
    double? recentSpeedMetersPerSecond,
  }) {
    final remaining = GeoMath.distanceMeters(position, target);
    _initialStraightDistance ??= remaining;
    final initial = _initialStraightDistance! <= 0
        ? remaining
        : _initialStraightDistance!;
    var percent = initial <= 0
        ? 1.0
        : (1 - remaining / initial).clamp(0.0, 1.0);
    if (percent < _maxPercent) {
      percent = _maxPercent;
    } else {
      _maxPercent = percent;
    }
    final covered = (initial * percent).clamp(0.0, initial);
    final arrived = remaining <= arrivalRadiusMeters;
    final eta = _etaSeconds(
      remainingMeters: remaining,
      routeDurationSeconds: null,
      percentComplete: percent,
      recentSpeedMetersPerSecond: recentSpeedMetersPerSecond,
    );
    return TripProgress(
      distanceCoveredMeters: covered,
      distanceRemainingMeters: remaining,
      percentComplete: percent,
      etaSeconds: eta,
      snappedPoint: position,
      segmentIndex: 0,
      distanceToRouteMeters: 0,
      arrived: arrived,
    );
  }

  double? _etaSeconds({
    required double remainingMeters,
    required double? routeDurationSeconds,
    required double percentComplete,
    required double? recentSpeedMetersPerSecond,
  }) {
    double? fromRoute;
    if (routeDurationSeconds != null && routeDurationSeconds > 0) {
      fromRoute = routeDurationSeconds * (1 - percentComplete);
    }
    double? fromSpeed;
    if (recentSpeedMetersPerSecond != null &&
        recentSpeedMetersPerSecond > 0.5) {
      fromSpeed = remainingMeters / recentSpeedMetersPerSecond;
    }
    if (fromRoute != null && fromSpeed != null) {
      return (fromRoute * 0.7) + (fromSpeed * 0.3);
    }
    return fromRoute ?? fromSpeed;
  }

  _SnapResult _snapToPolyline(List<RoutePoint> polyline, RoutePoint position) {
    var bestDistance = double.infinity;
    var bestPoint = polyline.first;
    var bestSegment = 0;
    var bestAlong = 0.0;
    var traversed = 0.0;

    for (var i = 0; i < polyline.length - 1; i++) {
      final a = polyline[i];
      final b = polyline[i + 1];
      final segmentLength = GeoMath.distanceMeters(a, b);
      final (projected, t) = GeoMath.projectOnSegment(position, a, b);
      final d = GeoMath.distanceMeters(position, projected);
      if (d < bestDistance) {
        bestDistance = d;
        bestPoint = projected;
        bestSegment = i;
        bestAlong = traversed + segmentLength * t;
      }
      traversed += segmentLength;
    }

    return _SnapResult(
      point: bestPoint,
      segmentIndex: bestSegment,
      distanceAlongMeters: bestAlong,
      distanceToRouteMeters: bestDistance.isFinite ? bestDistance : 0,
    );
  }

  double _polylineLength(List<RoutePoint> polyline) {
    var total = 0.0;
    for (var i = 0; i < polyline.length - 1; i++) {
      total += GeoMath.distanceMeters(polyline[i], polyline[i + 1]);
    }
    return total;
  }

  /// Splits [polyline] into covered (faded) and remaining (active) parts.
  static (List<RoutePoint> covered, List<RoutePoint> remaining) splitPolyline({
    required List<RoutePoint> polyline,
    required double distanceCoveredMeters,
  }) {
    if (polyline.length < 2) {
      return (List<RoutePoint>.from(polyline), const []);
    }
    if (distanceCoveredMeters <= 0) {
      return ([polyline.first], List<RoutePoint>.from(polyline));
    }

    final covered = <RoutePoint>[polyline.first];
    var remainingBudget = distanceCoveredMeters;
    for (var i = 0; i < polyline.length - 1; i++) {
      final a = polyline[i];
      final b = polyline[i + 1];
      final segment = GeoMath.distanceMeters(a, b);
      if (remainingBudget >= segment) {
        covered.add(b);
        remainingBudget -= segment;
        continue;
      }
      final t = segment <= 0 ? 0.0 : remainingBudget / segment;
      final split = GeoMath.interpolate(a, b, t);
      covered.add(split);
      final remaining = <RoutePoint>[split, ...polyline.sublist(i + 1)];
      return (covered, remaining);
    }
    return (covered, [polyline.last]);
  }
}

class _SnapResult {
  const _SnapResult({
    required this.point,
    required this.segmentIndex,
    required this.distanceAlongMeters,
    required this.distanceToRouteMeters,
  });

  final RoutePoint point;
  final int segmentIndex;
  final double distanceAlongMeters;
  final double distanceToRouteMeters;
}
