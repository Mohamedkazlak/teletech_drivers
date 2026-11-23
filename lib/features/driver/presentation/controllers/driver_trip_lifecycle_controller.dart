import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/errors/failures.dart';
import 'package:teletech_drivers/features/drivers_admin/presentation/state/trip_action_state.dart';
import 'package:teletech_drivers/features/tracking/data/services/geolocator_location_tracking_service.dart';
import 'package:teletech_drivers/features/tracking/data/services/phase_upload_retry.dart';
import 'package:teletech_drivers/features/tracking/domain/constants/map_defaults.dart';
import 'package:teletech_drivers/features/tracking/domain/services/location_tracking_service.dart';
import 'package:teletech_drivers/features/tracking/presentation/controllers/location_tracking_controller.dart';
import 'package:teletech_drivers/features/tracking/presentation/providers/location_tracking_service_provider.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_phase_payload.dart';
import 'package:teletech_drivers/features/trip/presentation/providers/trip_providers.dart';
import 'package:teletech_drivers/features/trip/presentation/utils/invalidate_trip_providers.dart';

/// Dependency Injection: Riverpod.
final driverTripLifecycleControllerProvider =
    NotifierProvider.autoDispose<
      DriverTripLifecycleController,
      TripActionState
    >(DriverTripLifecycleController.new);

/// Controller for driver phase actions (State: trip lifecycle).
class DriverTripLifecycleController extends Notifier<TripActionState> {
  final _retry = PhaseUploadRetry();

  @override
  TripActionState build() => const TripActionState();

  LocationTrackingService get _tracking =>
      ref.read(locationTrackingServiceProvider);

  GeolocatorLocationTrackingService? get _geoTracking {
    final service = _tracking;
    return service is GeolocatorLocationTrackingService ? service : null;
  }

  Future<bool> start(String tripId) {
    return _run(
      tripId: tripId,
      action: () async {
        await _requireLocationPermission(tripId);

        final source = ref.read(locationSourceProvider);
        final fresh = await source.getCurrentPosition(
          timeout: MapDefaults.currentPositionTimeout,
        );
        final position =
            fresh ??
            source.cachedPosition ??
            await source.getLastKnownPosition();
        if (position == null) {
          throw const LocationFailure(LocationErrorKind.timedOut);
        }

        await ref.read(startTripUseCaseProvider)(
          tripId: tripId,
          payload: StartTripPayload(
            startLat: position.latitude,
            startLng: position.longitude,
          ),
        );

        await _shareAfterTransition(tripId, TripTrackPhase.going);
      },
    );
  }

  Future<bool> arriveAtDestination(String tripId) {
    return _run(
      tripId: tripId,
      action: () async {
        final snapshot = _safeFinalize(TripTrackPhase.going);
        final payload = ArriveDestinationPayload.fromSnapshot(snapshot);
        await _persistAndUpload(
          tripId: tripId,
          upload: () => ref.read(arriveAtDestinationUseCaseProvider)(
            tripId: tripId,
            payload: payload,
          ),
          localPayload: {
            'kind': 'arrive',
            'goingRoute': payload.goingRoute,
            'goingDistanceMeters': payload.goingDistanceMeters,
          },
        );
        await _tracking.clearPhaseBuffer();
        await _tracking.stopTracking();
        await ref.read(locationTrackingControllerProvider.notifier).stop();
      },
    );
  }

  Future<bool> startReturn(String tripId) {
    return _run(
      tripId: tripId,
      action: () async {
        await _requireLocationPermission(tripId);
        await ref.read(startReturnUseCaseProvider)(tripId);
        await _shareAfterTransition(tripId, TripTrackPhase.returning);
      },
    );
  }

  /// The status is already saved. A tracking failure must not look like the
  /// trip action failed, or the next tap retries a finished transition.
  Future<void> _shareAfterTransition(
    String tripId,
    TripTrackPhase phase,
  ) async {
    try {
      await _startPhaseTracking(tripId: tripId, phase: phase);
      await ref.read(locationTrackingControllerProvider.notifier).start(tripId);
    } on Object {
      // The map can start tracking again from the live screen.
    }
  }

  Future<void> _requireLocationPermission(String tripId) async {
    final permission = await _tracking.ensurePermissions();
    if (permission == LocationPermissionOutcome.granted) return;
    // Surface denied / settings UI via the existing tracking banner.
    await ref.read(locationTrackingControllerProvider.notifier).start(tripId);
    throw switch (permission) {
      LocationPermissionOutcome.servicesDisabled => const LocationFailure(
        LocationErrorKind.servicesDisabled,
      ),
      LocationPermissionOutcome.permanentlyDenied => const LocationFailure(
        LocationErrorKind.permanentlyDenied,
      ),
      _ => const LocationFailure(LocationErrorKind.permissionDenied),
    };
  }

  Future<void> _startPhaseTracking({
    required String tripId,
    required TripTrackPhase phase,
  }) async {
    try {
      await _tracking.startTracking(tripId: tripId, phase: phase);
    } on StateError catch (error) {
      final message = error.message;
      if (message.contains('permission') ||
          message.contains('LocationPermissionOutcome')) {
        throw const LocationFailure(LocationErrorKind.permissionDenied);
      }
      rethrow;
    }
  }

  Future<bool> end(String tripId) {
    return _run(
      tripId: tripId,
      action: () async {
        final snapshot = _safeFinalize(TripTrackPhase.returning);
        final trip = await ref.read(getTripByIdUseCaseProvider)(tripId);
        final payload = EndTripPayload.fromSnapshot(
          snapshot: snapshot,
          goingDistanceMeters: trip?.goingDistanceMeters ?? 0,
        );
        await _persistAndUpload(
          tripId: tripId,
          upload: () => ref.read(endTripUseCaseProvider)(
            tripId: tripId,
            payload: payload,
          ),
          localPayload: {
            'kind': 'end',
            'returnRoute': payload.returnRoute,
            'returnDistanceMeters': payload.returnDistanceMeters,
            'goingDistanceMeters': payload.goingDistanceMeters,
          },
        );
        try {
          await _tracking.clearPhaseBuffer();
          await _geoTracking?.clearLocalTrip(tripId);
          await _tracking.stopTracking();
          await ref.read(locationTrackingControllerProvider.notifier).stop();
        } on Object {
          // The trip is already ended. Cleanup can fail without a retry.
        }
      },
    );
  }

  /// Retries offline phase finals after connectivity returns.
  Future<void> retryPendingPhaseUploads() async {
    final geo = _geoTracking;
    if (geo == null) return;

    for (final tripId in await geo.pendingUploadTripIds()) {
      final payload = await geo.loadPendingUpload(tripId);
      if (payload == null) continue;
      final kind = payload['kind'];
      try {
        if (kind == 'arrive') {
          await _retry.run(
            shouldRetry: _canRetryPhaseUpload,
            () => ref.read(arriveAtDestinationUseCaseProvider)(
              tripId: tripId,
              payload: ArriveDestinationPayload(
                goingRoute: payload['goingRoute'] as String? ?? '',
                goingDistanceMeters:
                    (payload['goingDistanceMeters'] as num?)?.toDouble() ?? 0,
              ),
            ),
          );
        } else if (kind == 'end') {
          await _retry.run(
            shouldRetry: _canRetryPhaseUpload,
            () => ref.read(endTripUseCaseProvider)(
              tripId: tripId,
              payload: EndTripPayload(
                returnRoute: payload['returnRoute'] as String? ?? '',
                returnDistanceMeters:
                    (payload['returnDistanceMeters'] as num?)?.toDouble() ?? 0,
                goingDistanceMeters:
                    (payload['goingDistanceMeters'] as num?)?.toDouble() ?? 0,
              ),
            ),
          );
        }
        await geo.clearPendingUpload(tripId);
      } on Object {
        // Leave pending for the next retry.
      }
    }
  }

  PhaseTrackSnapshot _safeFinalize(TripTrackPhase expected) {
    if (_tracking.activePhase == expected && _tracking.isTracking) {
      return _tracking.finalizeCurrentPhase();
    }
    return PhaseTrackSnapshot(
      phase: expected,
      encodedPolyline: '',
      distanceMeters: _tracking.activePhase == expected
          ? _tracking.distanceMeters
          : 0,
      points: _tracking.activePhase == expected
          ? _tracking.acceptedPoints
          : const [],
    );
  }

  Future<void> _persistAndUpload({
    required String tripId,
    required Future<void> Function() upload,
    required Map<String, dynamic> localPayload,
  }) async {
    await _geoTracking?.persistPendingUpload(
      tripId: tripId,
      payload: localPayload,
    );
    await _retry.run(upload, shouldRetry: _canRetryPhaseUpload);
    await _geoTracking?.clearPendingUpload(tripId);
  }

  Failure _friendly(Failure failure) {
    if (failure is ConflictFailure) return const InvalidStateFailure();
    if (failure is ServerFailure) {
      final message = failure.message ?? '';
      if (message.contains('cURL') ||
          message.contains('Exception') ||
          message.contains('Stack trace')) {
        return const UnknownFailure();
      }
    }
    return failure;
  }

  /// Client errors (422, 409, 403) will not succeed on a retry.
  static bool _canRetryPhaseUpload(Object error) {
    return error is NetworkFailure || error is ServerFailure;
  }

  Future<bool> _run({
    required String tripId,
    required Future<void> Function() action,
  }) async {
    if (state.isLoading) return false;

    state = TripActionState(isLoading: true, activeTripId: tripId);
    try {
      await action();
      if (!ref.mounted) return false;
      invalidateTripProviders(ref);
      state = const TripActionState();
      return true;
    } on Failure catch (failure) {
      if (!ref.mounted) return false;
      state = TripActionState(
        failure: _friendly(failure),
        activeTripId: tripId,
      );
      return false;
    } on Object {
      if (!ref.mounted) return false;
      state = TripActionState(
        failure: const UnknownFailure(),
        activeTripId: tripId,
      );
      return false;
    }
  }
}
