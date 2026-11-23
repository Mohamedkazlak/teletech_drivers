import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:teletech_drivers/features/tracking/domain/constants/map_defaults.dart';
import 'package:teletech_drivers/features/tracking/domain/services/location_source.dart';

/// Strategy: one shared device-GPS subscription via Geolocator.
///
/// Android delivers position streams through a single event channel. The
/// phase tracker and the live publisher both listen here so neither call
/// cancels the other. The native distance filter stays at 0 so a stopped
/// car still yields [MapDefaults.streamInterval] heartbeats.
class RealLocationSource implements LocationSource {
  RealLocationSource() {
    _hub = StreamController<Position>.broadcast(
      onListen: _ensureNative,
      onCancel: () {
        unawaited(_stopNative());
      },
    );
  }

  late final StreamController<Position> _hub;
  StreamSubscription<Position>? _native;
  Position? _cached;

  @override
  Position? get cachedPosition => _cached;

  @override
  Stream<Position> watchPositions({required int distanceFilterMeters}) {
    return _hub.stream;
  }

  @override
  Future<Position?> getLastKnownPosition() async {
    if (_cached != null) return _cached;
    try {
      final position = await Geolocator.getLastKnownPosition();
      if (position != null) _cached = position;
    } on Object {
      // Platform last-known is optional. Callers still have [cachedPosition].
    }
    return _cached;
  }

  @override
  Future<Position?> getCurrentPosition({required Duration timeout}) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(timeout);
      _cached = position;
      return position;
    } on Object {
      return null;
    }
  }

  @override
  Future<void> dispose() async {
    await _stopNative();
    if (!_hub.isClosed) await _hub.close();
  }

  void _ensureNative() {
    if (_native != null) return;
    _native = Geolocator.getPositionStream(
      locationSettings: _settings(),
    ).listen(
      (position) {
        _cached = position;
        if (!_hub.isClosed) _hub.add(position);
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!_hub.isClosed && _hub.hasListener) {
          _hub.addError(error, stackTrace);
        }
      },
      cancelOnError: false,
    );
  }

  Future<void> _stopNative() async {
    final native = _native;
    _native = null;
    await native?.cancel();
  }

  LocationSettings _settings() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: MapDefaults.streamDistanceFilterMeters,
        intervalDuration: MapDefaults.streamInterval,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: MapDefaults.fgsNotificationTitle,
          notificationText: MapDefaults.fgsNotificationText,
          enableWakeLock: true,
        ),
      );
    }
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: MapDefaults.streamDistanceFilterMeters,
        activityType: ActivityType.automotiveNavigation,
        pauseLocationUpdatesAutomatically: false,
        allowBackgroundLocationUpdates: true,
        showBackgroundLocationIndicator: true,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: MapDefaults.streamDistanceFilterMeters,
    );
  }
}
