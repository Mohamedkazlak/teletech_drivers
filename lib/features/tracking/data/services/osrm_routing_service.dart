import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import 'package:teletech_drivers/features/tracking/domain/constants/map_defaults.dart';
import 'package:teletech_drivers/features/tracking/domain/entities/driving_route.dart';
import 'package:teletech_drivers/features/tracking/domain/entities/route_point.dart';
import 'package:teletech_drivers/features/tracking/domain/services/geo_math.dart';
import 'package:teletech_drivers/features/tracking/domain/services/routing_service.dart';

/// Strategy: public OSRM demo server (no API key), 10 s timeout.
class OsrmRoutingService implements RoutingService {
  OsrmRoutingService({Dio? client}) : _client = client ?? Dio();

  final Dio _client;

  /// In-memory cache keyed by rounded origin/destination (leg-safe).
  final Map<String, DrivingRoute> _cache = {};

  @override
  Future<RoutingResult?> route({
    required LatLng start,
    required LatLng end,
  }) async {
    if (!MapDefaults.enableOsrmRouting) return null;

    final origin = RoutePoint(start.latitude, start.longitude);
    final destination = RoutePoint(end.latitude, end.longitude);
    final driving = await _fetchDriving(
      origin: origin,
      destination: destination,
    );
    if (driving == null || driving.isApproximate) return null;

    return RoutingResult(
      points: [for (final p in driving.points) LatLng(p.lat, p.lng)],
      distanceMeters: driving.distanceMeters,
      durationSeconds: driving.durationSeconds,
    );
  }

  /// Cached [DrivingRoute] helper used by map controllers / admin sheet.
  Future<DrivingRoute?> routeBetween({
    required RoutePoint origin,
    required RoutePoint destination,
    String? cacheKey,
  }) async {
    if (!MapDefaults.enableOsrmRouting) return null;

    final key = cacheKey ?? _key(origin, destination);
    final cached = _cache[key];
    if (cached != null) return cached;

    final fetched = await _fetchDriving(
      origin: origin,
      destination: destination,
    );
    if (fetched != null) {
      _cache[key] = fetched;
    }
    return fetched;
  }

  /// Returns a cached route without hitting the network.
  DrivingRoute? cached(String cacheKey) => _cache[cacheKey];

  void putCache(String cacheKey, DrivingRoute route) {
    _cache[cacheKey] = route;
  }

  void clearCache() => _cache.clear();

  void dispose() {
    clearCache();
    _client.close(force: true);
  }

  Future<DrivingRoute?> _fetchDriving({
    required RoutePoint origin,
    required RoutePoint destination,
  }) async {
    final uri = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '${origin.lng},${origin.lat};'
      '${destination.lng},${destination.lat}'
      '?overview=full&geometries=geojson',
    );

    try {
      final response = await _client.getUri<String>(
        uri,
        options: Options(
          responseType: ResponseType.plain,
          receiveTimeout: MapDefaults.osrmTimeout,
          sendTimeout: MapDefaults.osrmTimeout,
          headers: {
            'user-agent': MapDefaults.osrmUserAgent,
            'accept': 'application/json',
          },
        ),
      );
      if (response.statusCode != 200 || response.data == null) return null;

      final json = jsonDecode(response.data!) as Map<String, dynamic>;
      final routes = json['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) return null;

      final first = routes.first as Map<String, dynamic>;
      final geometry = first['geometry'] as Map<String, dynamic>?;
      final coordinates = geometry?['coordinates'] as List<dynamic>?;
      if (coordinates == null || coordinates.isEmpty) return null;

      final points = <RoutePoint>[
        for (final coord in coordinates)
          if (coord is List && coord.length >= 2)
            RoutePoint(
              (coord[1] as num).toDouble(),
              (coord[0] as num).toDouble(),
            ),
      ];
      if (points.length < 2) return null;

      final distance =
          (first['distance'] as num?)?.toDouble() ?? _polylineLength(points);
      final duration = (first['duration'] as num?)?.toDouble() ?? 0;

      return DrivingRoute(
        points: points,
        distanceMeters: distance,
        durationSeconds: duration,
      );
    } on Object {
      return null;
    }
  }

  String _key(RoutePoint origin, RoutePoint destination) {
    return '${origin.lat.toStringAsFixed(4)},${origin.lng.toStringAsFixed(4)}>'
        '${destination.lat.toStringAsFixed(4)},${destination.lng.toStringAsFixed(4)}';
  }

  double _polylineLength(List<RoutePoint> points) {
    var total = 0.0;
    for (var i = 0; i < points.length - 1; i++) {
      total += GeoMath.distanceMeters(points[i], points[i + 1]);
    }
    return total;
  }
}
