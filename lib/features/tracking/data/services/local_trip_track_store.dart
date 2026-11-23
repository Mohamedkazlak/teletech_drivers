import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:teletech_drivers/features/tracking/domain/entities/tracked_location_point.dart';
import 'package:teletech_drivers/features/tracking/domain/services/location_tracking_service.dart';

/// Persists accepted GPS points locally so a crash mid-trip does not lose the
/// going/return track.
class LocalTripTrackStore {
  LocalTripTrackStore({this._preferences});

  SharedPreferences? _preferences;

  static const _prefix = 'trip_track_v1_';
  static const _pendingPrefix = 'trip_pending_upload_v1_';

  Future<SharedPreferences> _prefs() async {
    return _preferences ??= await SharedPreferences.getInstance();
  }

  Future<void> savePoints({
    required String tripId,
    required TripTrackPhase phase,
    required List<TrackedLocationPoint> points,
    required double distanceMeters,
  }) async {
    final prefs = await _prefs();
    final payload = {
      'phase': phase.name,
      'distanceMeters': distanceMeters,
      'points': [
        for (final point in points)
          {
            'lat': point.lat,
            'lng': point.lng,
            'accuracyMeters': point.accuracyMeters,
            'speedMps': point.speedMps,
            'headingDegrees': point.headingDegrees,
            'timestamp': point.timestamp.toUtc().toIso8601String(),
          },
      ],
    };
    await prefs.setString(
      '$_prefix${tripId}_${phase.name}',
      jsonEncode(payload),
    );
  }

  Future<({List<TrackedLocationPoint> points, double distanceMeters})?>
  loadPoints({required String tripId, required TripTrackPhase phase}) async {
    final prefs = await _prefs();
    final raw = prefs.getString('$_prefix${tripId}_${phase.name}');
    if (raw == null || raw.isEmpty) return null;

    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return null;
    final pointsRaw = decoded['points'];
    if (pointsRaw is! List) return null;

    final points = <TrackedLocationPoint>[];
    for (final item in pointsRaw) {
      if (item is! Map) continue;
      final lat = item['lat'];
      final lng = item['lng'];
      final accuracy = item['accuracyMeters'];
      final speed = item['speedMps'];
      final heading = item['headingDegrees'];
      final timestamp = item['timestamp'];
      if (lat is! num ||
          lng is! num ||
          accuracy is! num ||
          speed is! num ||
          heading is! num ||
          timestamp is! String) {
        continue;
      }
      final parsed = DateTime.tryParse(timestamp);
      if (parsed == null) continue;
      points.add(
        TrackedLocationPoint(
          lat: lat.toDouble(),
          lng: lng.toDouble(),
          accuracyMeters: accuracy.toDouble(),
          speedMps: speed.toDouble(),
          headingDegrees: heading.toDouble(),
          timestamp: parsed.toUtc(),
        ),
      );
    }

    final distance = decoded['distanceMeters'];
    final distanceMeters = distance is num ? distance.toDouble() : 0.0;
    return (points: points, distanceMeters: distanceMeters);
  }

  Future<void> clearPoints({
    required String tripId,
    required TripTrackPhase phase,
  }) async {
    final prefs = await _prefs();
    await prefs.remove('$_prefix${tripId}_${phase.name}');
  }

  Future<void> clearTrip(String tripId) async {
    final prefs = await _prefs();
    for (final phase in TripTrackPhase.values) {
      await prefs.remove('$_prefix${tripId}_${phase.name}');
    }
    await prefs.remove('$_pendingPrefix$tripId');
  }

  Future<void> savePendingUpload({
    required String tripId,
    required Map<String, dynamic> payload,
  }) async {
    final prefs = await _prefs();
    await prefs.setString('$_pendingPrefix$tripId', jsonEncode(payload));
  }

  Future<Map<String, dynamic>?> loadPendingUpload(String tripId) async {
    final prefs = await _prefs();
    final raw = prefs.getString('$_pendingPrefix$tripId');
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return null;
    return decoded;
  }

  Future<void> clearPendingUpload(String tripId) async {
    final prefs = await _prefs();
    await prefs.remove('$_pendingPrefix$tripId');
  }

  Future<List<String>> pendingUploadTripIds() async {
    final prefs = await _prefs();
    return [
      for (final key in prefs.getKeys())
        if (key.startsWith(_pendingPrefix))
          key.substring(_pendingPrefix.length),
    ];
  }
}
