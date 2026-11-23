import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:teletech_drivers/features/tracking/data/services/local_trip_track_store.dart';
import 'package:teletech_drivers/features/tracking/data/services/real_location_source.dart';
import 'package:teletech_drivers/features/tracking/domain/constants/map_defaults.dart';
import 'package:teletech_drivers/features/tracking/domain/entities/tracked_location_point.dart';
import 'package:teletech_drivers/features/tracking/domain/services/geo_math.dart';
import 'package:teletech_drivers/features/tracking/domain/services/location_point_filter.dart';
import 'package:teletech_drivers/features/tracking/domain/services/location_source.dart';
import 'package:teletech_drivers/features/tracking/domain/services/location_tracking_service.dart';
import 'package:teletech_drivers/features/tracking/domain/services/polyline_encoder.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Strategy: Geolocator + local persistence + wake lock + FGS on Android.
class GeolocatorLocationTrackingService implements LocationTrackingService {
  GeolocatorLocationTrackingService({
    LocationSource? locationSource,
    this._permissionGate,
    this._filter = const LocationPointFilter(),
    LocalTripTrackStore? trackStore,
    this.persistEveryPoints = 20,
  }) : _source = locationSource ?? RealLocationSource(),
       _ownsSource = locationSource == null,
       _trackStore = trackStore ?? LocalTripTrackStore();

  final LocationSource _source;
  final bool _ownsSource;
  final Future<LocationPermissionOutcome> Function()? _permissionGate;
  final LocationPointFilter _filter;
  final LocalTripTrackStore _trackStore;
  final int persistEveryPoints;

  Position? _latestRaw;
  Object? _locationError;

  /// Position source this tracker listens to. Tests use this to confirm DI.
  @visibleForTesting
  LocationSource get locationSource => _source;

  /// Latest raw fix, kept when a later GPS read fails.
  Position? get latestPosition => _latestRaw;

  /// Last stream error. Null after a successful point.
  Object? get locationError => _locationError;

  final _acceptedController =
      StreamController<TrackedLocationPoint>.broadcast();
  final List<TrackedLocationPoint> _accepted = [];

  StreamSubscription<Position>? _positionSub;
  TrackedLocationPoint? _latestAccepted;
  String? _tripId;
  TripTrackPhase? _phase;
  double _distanceMeters = 0;
  var _pointsSincePersist = 0;
  var _tracking = false;

  @override
  Stream<TrackedLocationPoint> get acceptedLocations =>
      _acceptedController.stream;

  @override
  String? get activeTripId => _tripId;

  @override
  TripTrackPhase? get activePhase => _phase;

  @override
  bool get isTracking => _tracking;

  @override
  List<TrackedLocationPoint> get acceptedPoints => List.unmodifiable(_accepted);

  @override
  double get distanceMeters => _distanceMeters;

  @override
  Future<LocationPermissionOutcome> ensurePermissions() async {
    final gate = _permissionGate;
    if (gate != null) return gate();

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (defaultTargetPlatform == TargetPlatform.android &&
        (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever)) {
      final status = await ph.Permission.locationWhenInUse.request();
      if (status.isGranted || status.isLimited) {
        permission = LocationPermission.whileInUse;
      } else if (status.isPermanentlyDenied) {
        permission = LocationPermission.deniedForever;
      }
    }

    if (permission == LocationPermission.denied) {
      return LocationPermissionOutcome.denied;
    }
    if (permission == LocationPermission.deniedForever) {
      return LocationPermissionOutcome.permanentlyDenied;
    }

    final servicesOn = await Geolocator.isLocationServiceEnabled();
    if (!servicesOn) {
      return LocationPermissionOutcome.servicesDisabled;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      unawaited(ph.Permission.notification.request());
    }

    return LocationPermissionOutcome.granted;
  }

  @override
  Future<void> openAppSettings() async {
    await ph.openAppSettings();
  }

  @override
  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  @override
  Future<void> startTracking({
    required String tripId,
    required TripTrackPhase phase,
  }) async {
    final outcome = await ensurePermissions();
    if (outcome != LocationPermissionOutcome.granted) {
      throw StateError('Location permission not granted: $outcome');
    }

    await _haltStream(clearIdentity: false);

    _tripId = tripId;
    _phase = phase;
    _accepted.clear();
    _distanceMeters = 0;
    _pointsSincePersist = 0;
    _latestAccepted = null;

    final restored = await _trackStore.loadPoints(tripId: tripId, phase: phase);
    if (restored != null) {
      _accepted.addAll(restored.points);
      _distanceMeters = restored.distanceMeters;
      _latestAccepted = _accepted.isEmpty ? null : _accepted.last;
    }

    try {
      await WakelockPlus.enable();
    } on Object {
      // A missing wakelock must not stop the GPS subscription.
    }
    _tracking = true;
    _locationError = null;

    _positionSub = _source
        .watchPositions(
          distanceFilterMeters: MapDefaults.streamDistanceFilterMeters,
        )
        .listen(
          _onPosition,
          onError: (Object error) {
            _locationError = error;
          },
          cancelOnError: false,
        );
  }

  @override
  Future<void> switchPhase(TripTrackPhase phase) async {
    final tripId = _tripId;
    if (tripId == null) {
      throw StateError('Cannot switch phase without an active trip');
    }
    await startTracking(tripId: tripId, phase: phase);
  }

  @override
  Future<void> stopTracking() async {
    await _haltStream(clearIdentity: true);
  }

  Future<void> _haltStream({required bool clearIdentity}) async {
    await _positionSub?.cancel();
    _positionSub = null;
    _tracking = false;

    try {
      await WakelockPlus.disable();
    } on Object {
      // Best-effort; some platforms may reject when already disabled.
    }

    if (clearIdentity) {
      _accepted.clear();
      _distanceMeters = 0;
      _latestAccepted = null;
      _pointsSincePersist = 0;
      _tripId = null;
      _phase = null;
    }
  }

  /// Closes the accepted-points stream. Call when the DI scope is disposed.
  Future<void> dispose() async {
    await _haltStream(clearIdentity: true);
    if (_ownsSource) await _source.dispose();
    await _acceptedController.close();
  }

  @override
  PhaseTrackSnapshot finalizeCurrentPhase() {
    final phase = _phase;
    if (phase == null) {
      throw StateError('No active phase to finalize');
    }
    final points = List<TrackedLocationPoint>.from(_accepted);
    final encoded = PolylineEncoder.encode([
      for (final point in points) point.asRoutePoint,
    ]);
    return PhaseTrackSnapshot(
      phase: phase,
      encodedPolyline: encoded,
      distanceMeters: _distanceMeters,
      points: points,
    );
  }

  @override
  Future<void> clearPhaseBuffer() async {
    final tripId = _tripId;
    final phase = _phase;
    _accepted.clear();
    _distanceMeters = 0;
    _latestAccepted = null;
    _pointsSincePersist = 0;
    if (tripId != null && phase != null) {
      await _trackStore.clearPoints(tripId: tripId, phase: phase);
    }
  }

  Future<void> persistPendingUpload({
    required String tripId,
    required Map<String, dynamic> payload,
  }) {
    return _trackStore.savePendingUpload(tripId: tripId, payload: payload);
  }

  Future<Map<String, dynamic>?> loadPendingUpload(String tripId) {
    return _trackStore.loadPendingUpload(tripId);
  }

  Future<void> clearPendingUpload(String tripId) {
    return _trackStore.clearPendingUpload(tripId);
  }

  Future<List<String>> pendingUploadTripIds() {
    return _trackStore.pendingUploadTripIds();
  }

  Future<void> clearLocalTrip(String tripId) {
    return _trackStore.clearTrip(tripId);
  }

  void _onPosition(Position position) {
    if (!_tracking) return;
    _latestRaw = position;
    _locationError = null;

    final candidate = TrackedLocationPoint(
      lat: position.latitude,
      lng: position.longitude,
      accuracyMeters: position.accuracy,
      speedMps: _finiteOrZero(position.speed),
      headingDegrees: _finiteOrZero(position.heading),
      timestamp: position.timestamp.toUtc(),
    );

    if (!_filter.shouldAccept(candidate, lastAccepted: _latestAccepted)) {
      return;
    }

    if (_latestAccepted != null) {
      _distanceMeters += GeoMath.distanceMeters(
        _latestAccepted!.asRoutePoint,
        candidate.asRoutePoint,
      );
    }

    _accepted.add(candidate);
    _latestAccepted = candidate;
    _acceptedController.add(candidate);
    _pointsSincePersist++;

    if (_pointsSincePersist >= persistEveryPoints) {
      _pointsSincePersist = 0;
      unawaited(_persistAccepted());
    }
  }

  Future<void> _persistAccepted() async {
    final tripId = _tripId;
    final phase = _phase;
    if (tripId == null || phase == null) return;
    await _trackStore.savePoints(
      tripId: tripId,
      phase: phase,
      points: _accepted,
      distanceMeters: _distanceMeters,
    );
  }

  static double _finiteOrZero(double value) {
    if (value.isNaN || value.isInfinite) return 0;
    return value;
  }
}
