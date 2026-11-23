import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:teletech_drivers/core/errors/failures.dart';
import 'package:teletech_drivers/features/tracking/data/services/simulated_location_source.dart';
import 'package:teletech_drivers/features/tracking/domain/constants/map_defaults.dart';
import 'package:teletech_drivers/features/tracking/domain/entities/driver_location_publish_outcome.dart';
import 'package:teletech_drivers/features/tracking/domain/services/location_publish_throttle.dart';
import 'package:teletech_drivers/features/tracking/domain/services/location_source.dart';
import 'package:teletech_drivers/features/tracking/presentation/providers/location_tracking_service_provider.dart';
import 'package:teletech_drivers/features/tracking/presentation/providers/tracking_providers.dart';
import 'package:teletech_drivers/features/tracking/presentation/state/location_tracking_state.dart';

/// Dependency Injection: Riverpod. Singleton-style controller for GPS sharing.
final locationTrackingControllerProvider =
    NotifierProvider<LocationTrackingController, LocationTrackingState>(
      LocationTrackingController.new,
    );

/// Starts / stops GPS and throttled live-location publishes without blocking the UI.
///
/// First publish ignores the usual throttle so Drivers Admin sees the driver
/// immediately; throttling applies from the second point onward.
class LocationTrackingController extends Notifier<LocationTrackingState>
    with WidgetsBindingObserver {
  StreamSubscription<Position>? _positionSub;
  final _publishThrottle = LocationPublishThrottle();
  var _starting = false;
  var _listening = false;
  var _observingLifecycle = false;
  LocationSource? _overrideSource;
  Position? _lastPublished;

  LocationSource _source() =>
      _overrideSource ?? ref.read(locationSourceProvider);

  /// True while [start] is in progress (used to avoid resume/start races).
  bool get isStarting => _starting;

  @override
  LocationTrackingState build() {
    if (!_observingLifecycle) {
      WidgetsBinding.instance.addObserver(this);
      _observingLifecycle = true;
      ref.onDispose(() {
        WidgetsBinding.instance.removeObserver(this);
        _observingLifecycle = false;
        unawaited(_disposeStreams());
      });
    } else {
      ref.onDispose(_disposeStreams);
    }
    return const LocationTrackingState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final tripId = this.state.tripId;
    if (tripId == null || _starting || this.state.isSharing) return;
    if (!this.state.warningBanner) return;
    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 300), () {
        if (!ref.mounted) return;
        unawaited(start(tripId));
      }),
    );
  }

  /// Starts sharing for [tripId]. Returns false when permission is denied
  /// (caller may still proceed with the trip and show a warning).
  Future<bool> start(String tripId) async {
    if (_starting) return state.isSharing;
    if (state.isSharing && state.tripId == tripId && _positionSub != null) {
      return true;
    }

    _starting = true;
    state = state.copyWith(
      status: LocationTrackingStatus.requestingPermission,
      tripId: tripId,
      clearFailure: true,
      warningBanner: false,
    );

    try {
      final permitted = await _ensurePermission();
      if (!permitted) {
        state = state.copyWith(tripId: tripId, warningBanner: true);
        return false;
      }

      await _listen(tripId);
      return true;
    } on Failure catch (failure) {
      state = state.copyWith(
        status: LocationTrackingStatus.error,
        failure: failure,
        tripId: tripId,
        warningBanner: true,
      );
      return false;
    } on Object {
      state = state.copyWith(
        status: LocationTrackingStatus.error,
        failure: const UnknownFailure(),
        tripId: tripId,
        warningBanner: true,
      );
      return false;
    } finally {
      _starting = false;
    }
  }

  /// High-accuracy one-shot used by TripBootstrap after last-known.
  Future<void> refreshCurrentPosition() async {
    final tripId = state.tripId;
    if (tripId == null) return;
    if (state.warningBanner && !state.isSharing) return;

    final last = await _source().getLastKnownPosition();
    if (last != null) {
      await _onPosition(
        last,
        tripId,
        forcePublish: !_publishThrottle.hasPublishedOnce,
      );
    }

    final current = await _source().getCurrentPosition(
      timeout: MapDefaults.currentPositionTimeout,
    );
    if (current != null) {
      await _onPosition(
        current,
        tripId,
        forcePublish: !_publishThrottle.hasPublishedOnce,
      );
      return;
    }
    if (!ref.mounted) return;
    state = state.copyWith(
      status: state.position == null
          ? LocationTrackingStatus.error
          : LocationTrackingStatus.sharing,
      failure: const LocationFailure(LocationErrorKind.timedOut),
      warningBanner: true,
      tripId: tripId,
    );
  }

  /// Debug-only: swap the GPS pipeline for a simulated source.
  Future<void> useSimulatedLocationSource(
    SimulatedLocationSource source,
  ) async {
    assert(!kReleaseMode, 'Simulation is debug-only');
    if (!kDebugMode) return;
    final tripId = state.tripId;
    if (tripId == null) return;

    await _disposeStreams();
    _overrideSource = source;
    _publishThrottle.reset();
    _lastPublished = null;
    await _listen(tripId);
  }

  /// Restores the real GPS pipeline after debug simulation.
  Future<void> useRealLocationSource() async {
    final tripId = state.tripId;
    await _disposeStreams();
    _overrideSource = null;
    _publishThrottle.reset();
    _lastPublished = null;
    if (tripId != null && state.isSharing) {
      await _listen(tripId);
    }
  }

  /// Exercises publish handling without the GPS permission flow.
  @visibleForTesting
  Future<void> handlePositionForTest(
    Position position, {
    required String tripId,
    bool forcePublish = true,
  }) {
    return _onPosition(position, tripId, forcePublish: forcePublish);
  }

  Future<void> stop() async {
    final tripId = state.tripId;
    await _disposeStreams();
    _publishThrottle.reset();
    _overrideSource = null;
    _lastPublished = null;

    Failure? stopFailure;
    try {
      await ref.read(clearTrackingUseCaseProvider)();
    } on Failure catch (failure) {
      stopFailure = failure;
    }

    state = LocationTrackingState(
      status: LocationTrackingStatus.idle,
      tripId: tripId,
      failure: stopFailure,
      warningBanner: stopFailure != null,
    );
  }

  /// No-op when idle; used before sign-out.
  Future<void> stopIfNeeded() async {
    if (state.status == LocationTrackingStatus.idle &&
        state.tripId == null &&
        _positionSub == null) {
      return;
    }
    await stop();
  }

  Future<void> openAppSettings() async {
    await ph.openAppSettings();
  }

  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  /// Tap handler for the warning banner: open the right settings, then retry.
  Future<void> fixSharing() async {
    final tripId = state.tripId;
    if (tripId == null) return;

    if (state.status == LocationTrackingStatus.permissionPermanentlyDenied) {
      await openAppSettings();
      return;
    }
    if (state.status == LocationTrackingStatus.servicesDisabled) {
      await openLocationSettings();
      return;
    }
    await start(tripId);
  }

  Future<void> retryPermission(String tripId) => start(tripId);

  Future<bool> _ensurePermission() async {
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
      state = state.copyWith(
        status: LocationTrackingStatus.permissionDenied,
        warningBanner: true,
      );
      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      state = state.copyWith(
        status: LocationTrackingStatus.permissionPermanentlyDenied,
        warningBanner: true,
      );
      return false;
    }

    final servicesOn = await Geolocator.isLocationServiceEnabled();
    if (!servicesOn) {
      state = state.copyWith(
        status: LocationTrackingStatus.servicesDisabled,
        warningBanner: true,
      );
      return false;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      unawaited(ph.Permission.notification.request());
    }

    return true;
  }

  Future<void> _listen(String tripId) async {
    if (_listening) return;
    _listening = true;
    try {
      await _disposeStreams();

      _positionSub = _source()
          .watchPositions(
            distanceFilterMeters: MapDefaults.streamDistanceFilterMeters,
          )
          .listen(
            (position) => unawaited(_onPosition(position, tripId)),
            onError: (Object _) {
              if (!ref.mounted) return;
              final kept = state.position ?? _source().cachedPosition;
              state = state.copyWith(
                status: kept == null
                    ? LocationTrackingStatus.error
                    : LocationTrackingStatus.sharing,
                position: kept,
                tripId: tripId,
                failure: const LocationFailure(LocationErrorKind.timedOut),
                warningBanner: true,
              );
            },
            cancelOnError: false,
          );

      state = state.copyWith(
        status: LocationTrackingStatus.sharing,
        tripId: tripId,
        warningBanner: false,
        clearFailure: true,
      );

      final source = _source();
      final last = await source.getLastKnownPosition();
      if (last != null) {
        await _onPosition(last, tripId, forcePublish: true);
      }
      final current = await source.getCurrentPosition(
        timeout: MapDefaults.currentPositionTimeout,
      );
      if (!ref.mounted) return;
      if (current != null) {
        await _onPosition(
          current,
          tripId,
          forcePublish: !_publishThrottle.hasPublishedOnce,
        );
      } else if (state.position == null && last == null) {
        state = state.copyWith(
          status: LocationTrackingStatus.error,
          tripId: tripId,
          failure: const LocationFailure(LocationErrorKind.timedOut),
          warningBanner: true,
        );
      } else if (current == null) {
        state = state.copyWith(
          status: LocationTrackingStatus.sharing,
          tripId: tripId,
          failure: const LocationFailure(LocationErrorKind.timedOut),
          warningBanner: true,
        );
      }
    } finally {
      _listening = false;
    }
  }

  Future<void> _onPosition(
    Position position,
    String tripId, {
    bool forcePublish = false,
  }) async {
    if (!ref.mounted) return;

    final previous = state.position;
    final movedEnough =
        previous == null ||
        Geolocator.distanceBetween(
              previous.latitude,
              previous.longitude,
              position.latitude,
              position.longitude,
            ) >=
            1;

    if (movedEnough || !state.isSharing || state.warningBanner) {
      state = state.copyWith(
        status: LocationTrackingStatus.sharing,
        position: position,
        tripId: tripId,
      );
    }

    final isFirstPublish = !_publishThrottle.hasPublishedOnce;
    final maxAccuracy = isFirstPublish
        ? 500.0
        : MapDefaults.maxAcceptedAccuracyMeters;
    if (position.accuracy > maxAccuracy) return;

    final now = DateTime.now().toUtc();
    final movedFromPublish = _lastPublished == null
        ? 0.0
        : Geolocator.distanceBetween(
            _lastPublished!.latitude,
            _lastPublished!.longitude,
            position.latitude,
            position.longitude,
          );
    if (!_publishThrottle.shouldSend(
      now,
      force: forcePublish || isFirstPublish,
      movedMeters: movedFromPublish,
    )) {
      return;
    }
    _publishThrottle.recordAttempt(now);

    try {
      // Sharing runs only during going / returning, so the trip is in progress.
      final outcome = await ref.read(publishLocationUseCaseProvider)(
        position: position,
        tripId: tripId,
        tripInProgress: true,
      );
      if (!ref.mounted) return;
      if (outcome == DriverLocationPublishOutcome.published) {
        _lastPublished = position;
        state = state.copyWith(
          status: LocationTrackingStatus.sharing,
          position: position,
          tripId: tripId,
          warningBanner: false,
          clearFailure: true,
        );
      }
    } on Failure catch (failure) {
      if (!ref.mounted) return;
      state = state.copyWith(
        status: LocationTrackingStatus.sharing,
        position: position,
        tripId: tripId,
        failure: failure,
        warningBanner: true,
      );
    } on Object {
      if (!ref.mounted) return;
      state = state.copyWith(
        status: LocationTrackingStatus.sharing,
        position: position,
        tripId: tripId,
        failure: const UnknownFailure(),
        warningBanner: true,
      );
    }
  }

  Future<void> _disposeStreams() async {
    await _positionSub?.cancel();
    _positionSub = null;
  }
}
