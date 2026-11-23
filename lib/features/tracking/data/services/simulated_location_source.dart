import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:teletech_drivers/features/tracking/domain/entities/route_point.dart';
import 'package:teletech_drivers/features/tracking/domain/services/geo_math.dart';
import 'package:teletech_drivers/features/tracking/domain/services/location_source.dart';

/// Strategy: debug-only walk along a route polyline.
///
/// Impossible to activate in release: [kReleaseMode] assert in the constructor
/// and on stream / one-shot reads. Availability must not use this unless the
/// debug simulated-location toggle is explicitly on.
class SimulatedLocationSource implements LocationSource {
  SimulatedLocationSource({
    required List<RoutePoint> route,
    RoutePoint? startNear,
    double speedKmh = 40,
  }) : assert(!kReleaseMode, 'SimulatedLocationSource is debug-only'),
       _route = List<RoutePoint>.from(route),
       _speedKmh = speedKmh.clamp(10, 120) {
    _placeStart(startNear);
  }

  final _controller = StreamController<Position>.broadcast();
  final _random = math.Random();
  List<RoutePoint> _route;
  double _speedKmh;
  var _paused = false;
  var _segmentIndex = 0;
  var _distanceIntoSegment = 0.0;
  Timer? _timer;
  Position? _last;
  var _listening = false;

  double get speedKmh => _speedKmh;
  bool get isPaused => _paused;

  set speedKmh(double value) => _speedKmh = value.clamp(10, 120);

  void updateRoute(List<RoutePoint> route, {RoutePoint? startNear}) {
    if (route.length < 2) return;
    _route = List<RoutePoint>.from(route);
    _placeStart(startNear ?? currentPoint);
  }

  void pause() => _paused = true;

  void resume() => _paused = false;

  void jumpToPercent(double percent) {
    if (_route.length < 2) return;
    final total = _totalLength();
    if (total <= 0) return;
    final target = (total * percent.clamp(0.0, 1.0));
    var walked = 0.0;
    for (var i = 0; i < _route.length - 1; i++) {
      final seg = GeoMath.distanceMeters(_route[i], _route[i + 1]);
      if (walked + seg >= target) {
        _segmentIndex = i;
        _distanceIntoSegment = target - walked;
        _emit(_pointOnRoute());
        return;
      }
      walked += seg;
    }
    _segmentIndex = _route.length - 2;
    _distanceIntoSegment = GeoMath.distanceMeters(
      _route[_segmentIndex],
      _route.last,
    );
    _emit(_pointOnRoute());
  }

  @override
  Position? get cachedPosition => _last;

  RoutePoint? get currentPoint {
    final last = _last;
    if (last == null) return null;
    return RoutePoint(last.latitude, last.longitude);
  }

  @override
  Stream<Position> watchPositions({required int distanceFilterMeters}) {
    assert(!kReleaseMode, 'SimulatedLocationSource is debug-only');
    if (!_listening) {
      _listening = true;
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
      _emit(_pointOnRoute());
    }
    return _controller.stream;
  }

  @override
  Future<Position?> getLastKnownPosition() async {
    assert(!kReleaseMode, 'SimulatedLocationSource is debug-only');
    return _last ?? _emit(_pointOnRoute());
  }

  @override
  Future<Position?> getCurrentPosition({required Duration timeout}) async {
    assert(!kReleaseMode, 'SimulatedLocationSource is debug-only');
    return _last ?? _emit(_pointOnRoute());
  }

  @override
  Future<void> dispose() async {
    _timer?.cancel();
    _timer = null;
    await _controller.close();
  }

  void _placeStart(RoutePoint? startNear) {
    if (_route.length < 2) {
      _segmentIndex = 0;
      _distanceIntoSegment = 0;
      return;
    }
    if (startNear == null) {
      _segmentIndex = 0;
      _distanceIntoSegment = 0;
      return;
    }
    var bestDistance = double.infinity;
    var bestSegment = 0;
    var bestInto = 0.0;
    for (var i = 0; i < _route.length - 1; i++) {
      final (projected, t) = GeoMath.projectOnSegment(
        startNear,
        _route[i],
        _route[i + 1],
      );
      final d = GeoMath.distanceMeters(startNear, projected);
      if (d < bestDistance) {
        bestDistance = d;
        bestSegment = i;
        bestInto =
            GeoMath.distanceMeters(_route[i], _route[i + 1]) * t;
      }
    }
    // Only snap if already roughly on-route; otherwise start at route origin.
    if (bestDistance <= 80) {
      _segmentIndex = bestSegment;
      _distanceIntoSegment = bestInto;
    } else {
      _segmentIndex = 0;
      _distanceIntoSegment = 0;
    }
  }

  void _tick() {
    if (_paused || _route.length < 2 || _controller.isClosed) return;
    final metersPerSecond = _speedKmh / 3.6;
    var step = metersPerSecond;
    while (step > 0 && _segmentIndex < _route.length - 1) {
      final a = _route[_segmentIndex];
      final b = _route[_segmentIndex + 1];
      final segLen = GeoMath.distanceMeters(a, b);
      final left = segLen - _distanceIntoSegment;
      if (step < left) {
        _distanceIntoSegment += step;
        step = 0;
      } else {
        step -= left;
        _segmentIndex++;
        _distanceIntoSegment = 0;
      }
    }
    _emit(_pointOnRoute());
  }

  RoutePoint _pointOnRoute() {
    if (_route.isEmpty) return const RoutePoint(0, 0);
    if (_segmentIndex >= _route.length - 1) {
      return _route.last;
    }
    final a = _route[_segmentIndex];
    final b = _route[_segmentIndex + 1];
    final segLen = GeoMath.distanceMeters(a, b);
    final t = segLen <= 0 ? 0.0 : (_distanceIntoSegment / segLen).clamp(0.0, 1.0);
    final base = GeoMath.interpolate(a, b, t);
    // Small random jitter (~2–4 m) so the path looks realistic.
    final jitterLat = (_random.nextDouble() - 0.5) * 0.00004;
    final jitterLng = (_random.nextDouble() - 0.5) * 0.00004;
    return RoutePoint(base.lat + jitterLat, base.lng + jitterLng);
  }

  Position _emit(RoutePoint point) {
    final heading = _segmentIndex < _route.length - 1
        ? GeoMath.bearingDegrees(
            _route[_segmentIndex],
            _route[math.min(_segmentIndex + 1, _route.length - 1)],
          )
        : (_last?.heading ?? 0);
    final position = Position(
      longitude: point.lng,
      latitude: point.lat,
      timestamp: DateTime.now(),
      accuracy: 8,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: heading,
      headingAccuracy: 5,
      speed: _speedKmh / 3.6,
      speedAccuracy: 1,
    );
    _last = position;
    if (!_controller.isClosed) {
      _controller.add(position);
    }
    return position;
  }

  double _totalLength() {
    var total = 0.0;
    for (var i = 0; i < _route.length - 1; i++) {
      total += GeoMath.distanceMeters(_route[i], _route[i + 1]);
    }
    return total;
  }
}
