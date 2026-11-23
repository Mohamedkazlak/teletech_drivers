import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:teletech_drivers/features/tracking/data/providers/simulated_location_providers.dart';
import 'package:teletech_drivers/features/place/presentation/providers/place_providers.dart';
import 'package:teletech_drivers/features/tracking/data/services/simulated_location_source.dart';
import 'package:teletech_drivers/features/tracking/domain/constants/map_defaults.dart';
import 'package:teletech_drivers/features/tracking/domain/entities/driving_route.dart';
import 'package:teletech_drivers/features/tracking/domain/entities/route_point.dart';
import 'package:teletech_drivers/features/tracking/domain/entities/tracked_location_point.dart';
import 'package:teletech_drivers/features/tracking/domain/entities/trip_endpoint.dart';
import 'package:teletech_drivers/features/tracking/domain/services/geo_math.dart';
import 'package:teletech_drivers/features/tracking/domain/services/location_tracking_service.dart';
import 'package:teletech_drivers/features/tracking/domain/services/trip_endpoint_resolver.dart';
import 'package:teletech_drivers/features/tracking/domain/services/trip_progress_calculator.dart';
import 'package:teletech_drivers/features/tracking/presentation/controllers/location_tracking_controller.dart';
import 'package:teletech_drivers/features/tracking/presentation/providers/location_tracking_service_provider.dart';
import 'package:teletech_drivers/features/tracking/presentation/providers/tracking_providers.dart';
import 'package:teletech_drivers/features/tracking/presentation/state/trip_navigation_state.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_status.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request.dart';
import 'package:teletech_drivers/features/trip_request/presentation/providers/trip_request_providers.dart';

/// Dependency Injection: Riverpod. One navigation session per trip.
final tripNavigationControllerProvider = NotifierProvider.autoDispose
    .family<TripNavigationController, TripNavigationState, String>(
      TripNavigationController.new,
    );

/// Orchestrates bootstrap, route, progress, and optional debug simulation.
class TripNavigationController extends Notifier<TripNavigationState> {
  TripNavigationController(this.tripId);

  final String tripId;

  final _calculator = TripProgressCalculator(
    arrivalRadiusMeters: MapDefaults.arrivalRadiusMeters,
  );
  final _resolver = TripEndpointResolver();

  DateTime? _lastRerouteAt;
  var _bootstrapped = false;
  var _fetchingRoute = false;
  SimulatedLocationSource? _simulator;
  StreamSubscription<TrackedLocationPoint>? _travelledSub;
  final List<double> _recentSpeeds = [];

  @override
  TripNavigationState build() {
    ref.onDispose(() {
      unawaited(_travelledSub?.cancel());
      _travelledSub = null;
      unawaited(_simulator?.dispose());
      _simulator = null;
    });
    return const TripNavigationState();
  }

  /// Runs once when the live map opens for an active / just-started trip.
  Future<void> bootstrap(Trip trip, {required String languageCode}) async {
    if (_bootstrapped) {
      _syncLegFromTrip(trip);
      _syncTravelledFromService();
      _recalculateFromTracking();
      return;
    }
    _bootstrapped = true;
    state = state.copyWith(
      bootstrapping: true,
      locatingPosition: true,
      positionTimedOut: false,
      leg: trip.status == TripStatus.returning
          ? TripLeg.returning
          : TripLeg.going,
    );

    await _completeStep(TripBootstrapStep.gettingLocation);
    await _ensurePhaseTracking(trip);
    final tracking = ref.read(locationTrackingControllerProvider.notifier);
    unawaited(tracking.start(tripId));
    await tracking.refreshCurrentPosition();

    var driverPos = ref.read(locationTrackingControllerProvider).position;
    driverPos ??= await _waitForPosition(MapDefaults.currentPositionTimeout);

    final timedOut = driverPos == null;
    state = state.copyWith(
      locatingPosition: false,
      waitingForGps: timedOut,
      positionTimedOut: timedOut,
    );

    await _completeStep(TripBootstrapStep.loadingLocations);
    final driverPoint = driverPos == null
        ? null
        : RoutePoint(driverPos.latitude, driverPos.longitude);

    List<TripRequest> requests = const [];
    if (trip.requestIds.isNotEmpty) {
      try {
        requests = await ref.read(
          tripRequestsByIdsProvider(trip.requestIds.join(',')).future,
        );
      } on Object {
        // Rules/network: still navigate from trip summaries + places.
        requests = const [];
      }
    }
    final places = await ref.read(allPlacesProvider.future);

    var endpoints = await _resolver.resolve(
      trip: trip,
      requests: requests,
      places: places,
      languageCode: languageCode,
      driverFallback: driverPoint,
    );

    // Returning: navigate back to the trip origin Place.
    if (trip.status == TripStatus.returning) {
      endpoints = TripEndpoints(from: endpoints.to, to: endpoints.from);
    }

    state = state.copyWith(endpoints: endpoints);
    _listenTravelledPath();

    await _completeStep(TripBootstrapStep.preparingRoute);
    await _ensureRouteForCurrentLeg(force: false);

    await _completeStep(TripBootstrapStep.sharingLocation);
    final stillWaiting =
        ref.read(locationTrackingControllerProvider).position == null;
    state = state.copyWith(
      bootstrapping: false,
      bootstrapStep: TripBootstrapStep.done,
      waitingForGps: stillWaiting,
      completedBootstrap: {
        ...state.completedBootstrap,
        TripBootstrapStep.sharingLocation,
        TripBootstrapStep.done,
      },
    );

    _recalculateFromTracking();
  }

  /// Manual / timeout retry for the initial high-accuracy fix.
  Future<void> retryLocatePosition() async {
    state = state.copyWith(
      locatingPosition: true,
      positionTimedOut: false,
      waitingForGps: true,
    );
    final tracking = ref.read(locationTrackingControllerProvider.notifier);
    await tracking.refreshCurrentPosition();
    var pos = ref.read(locationTrackingControllerProvider).position;
    pos ??= await _waitForPosition(MapDefaults.currentPositionTimeout);
    final timedOut = pos == null;
    state = state.copyWith(
      locatingPosition: false,
      waitingForGps: timedOut,
      positionTimedOut: timedOut,
    );
    if (!timedOut) {
      await _ensureRouteForCurrentLeg(force: true);
      _recalculateFromTracking();
    }
  }

  /// Manual "Recalculate route" from the current GPS fix.
  Future<void> recalculateRoute() async {
    _lastRerouteAt = DateTime.now().toUtc();
    await _ensureRouteForCurrentLeg(force: true);
    _calculator.reset();
    _recalculateFromTracking();
  }

  void onPosition(Position position) {
    if (state.waitingForGps ||
        state.positionTimedOut ||
        state.locatingPosition) {
      state = state.copyWith(
        waitingForGps: false,
        positionTimedOut: false,
        locatingPosition: false,
      );
    }
    _updateProgress(
      RoutePoint(position.latitude, position.longitude),
      position.speed,
    );
    unawaited(_maybeReroute(RoutePoint(position.latitude, position.longitude)));
  }

  Future<void> startReturnLeg() async {
    if (state.leg == TripLeg.returning) return;
    final current = state.endpoints;
    if (current == null) return;

    _calculator.reset();
    _lastRerouteAt = null;
    state = state.copyWith(
      leg: TripLeg.returning,
      endpoints: TripEndpoints(from: current.to, to: current.from),
      clearRoute: true,
      clearProgress: true,
      travelledPoints: const [],
    );
    _syncTravelledFromService();
    await _ensureRouteForCurrentLeg(force: true);
    _recalculateFromTracking();
    if (state.simulating && kDebugMode) {
      await _restartSimulator();
    }
  }

  Future<void> setSimulating(bool enabled) async {
    assert(!kReleaseMode, 'Simulation is debug-only');
    if (!kDebugMode) return;

    if (!enabled) {
      await _simulator?.dispose();
      _simulator = null;
      state = state.copyWith(simulating: false, simulatePaused: false);
      ref.read(availabilitySimulatedLocationSourceProvider.notifier).clear();
      ref
          .read(availabilityAllowSimulatedLocationProvider.notifier)
          .setEnabled(false);
      await ref
          .read(locationTrackingControllerProvider.notifier)
          .useRealLocationSource();
      return;
    }

    final route = state.route;
    if (route == null || !route.isUsable) return;

    state = state.copyWith(simulating: true, simulatePaused: false);
    ref
        .read(availabilityAllowSimulatedLocationProvider.notifier)
        .setEnabled(true);
    await _restartSimulator();
  }

  void setSimulateSpeed(double kmh) {
    assert(kDebugMode);
    if (!kDebugMode) return;
    state = state.copyWith(simulateSpeedKmh: kmh.clamp(10, 120));
    _simulator?.speedKmh = state.simulateSpeedKmh;
  }

  void setSimulatePaused(bool paused) {
    assert(kDebugMode);
    if (!kDebugMode) return;
    state = state.copyWith(simulatePaused: paused);
    if (paused) {
      _simulator?.pause();
    } else {
      _simulator?.resume();
    }
  }

  void jumpSimulatorToPercent(double percent) {
    assert(kDebugMode);
    if (!kDebugMode) return;
    _simulator?.jumpToPercent(percent);
  }

  Future<void> _restartSimulator() async {
    final route = state.route;
    if (route == null || !route.isUsable) return;

    await _simulator?.dispose();
    final trackingPos = ref.read(locationTrackingControllerProvider).position;
    final startNear = trackingPos == null
        ? null
        : RoutePoint(trackingPos.latitude, trackingPos.longitude);

    _simulator = SimulatedLocationSource(
      route: route.points,
      startNear: startNear,
      speedKmh: state.simulateSpeedKmh,
    );
    ref
        .read(availabilitySimulatedLocationSourceProvider.notifier)
        .attach(_simulator!);
    await ref
        .read(locationTrackingControllerProvider.notifier)
        .useSimulatedLocationSource(_simulator!);
  }

  Future<void> _completeStep(TripBootstrapStep step) async {
    state = state.copyWith(
      bootstrapStep: step,
      completedBootstrap: {...state.completedBootstrap, step},
    );
    await Future<void>.delayed(const Duration(milliseconds: 280));
  }

  Future<Position?> _waitForPosition(Duration timeout) async {
    final existing = ref.read(locationTrackingControllerProvider).position;
    if (existing != null) return existing;

    final completer = Completer<Position?>();
    late final ProviderSubscription<dynamic> sub;
    Timer? timer;

    sub = ref.listen(locationTrackingControllerProvider, (previous, next) {
      final position = next.position;
      if (position != null && !completer.isCompleted) {
        completer.complete(position);
      }
    });
    timer = Timer(timeout, () {
      if (!completer.isCompleted) completer.complete(null);
    });

    try {
      return await completer.future;
    } finally {
      timer.cancel();
      sub.close();
    }
  }

  /// Planned route always starts at the driver's current fix.
  Future<void> _ensureRouteForCurrentLeg({required bool force}) async {
    final to = state.endpoints?.to.point;
    final trackingPos = ref.read(locationTrackingControllerProvider).position;
    if (to == null || trackingPos == null) {
      if (to != null && state.endpoints?.from.point != null) {
        // No GPS yet — keep a dashed fallback from resolved from→to.
        final from = state.endpoints!.from.point!;
        final distance = GeoMath.distanceMeters(from, to);
        state = state.copyWith(
          route: DrivingRoute.straight(
            origin: from,
            destination: to,
            distanceMeters: distance,
          ),
        );
      }
      return;
    }

    final from = RoutePoint(trackingPos.latitude, trackingPos.longitude);
    final cacheKey =
        '$tripId:${state.leg.name}:${_pointKey(from)}>${_pointKey(to)}';
    final osrm = ref.read(osrmRoutingServiceProvider);
    if (!force) {
      final cached = osrm.cached(cacheKey);
      if (cached != null) {
        state = state.copyWith(route: cached);
        return;
      }
    }

    if (_fetchingRoute) return;
    _fetchingRoute = true;
    state = state.copyWith(fetchingRoute: true);
    try {
      final fetched = await osrm.routeBetween(
        origin: from,
        destination: to,
        cacheKey: cacheKey,
      );
      if (fetched != null) {
        state = state.copyWith(route: fetched);
        return;
      }
      final distance = GeoMath.distanceMeters(from, to);
      final fallback = DrivingRoute.straight(
        origin: from,
        destination: to,
        distanceMeters: distance,
      );
      osrm.putCache(cacheKey, fallback);
      state = state.copyWith(route: fallback);
    } finally {
      _fetchingRoute = false;
      state = state.copyWith(fetchingRoute: false);
    }
  }

  Future<void> _maybeReroute(RoutePoint position) async {
    final route = state.route;
    final progress = state.progress;
    if (route == null || route.isApproximate || progress == null) return;
    if (progress.distanceToRouteMeters <= MapDefaults.offRouteThresholdMeters) {
      return;
    }

    final last = _lastRerouteAt;
    if (last != null &&
        DateTime.now().toUtc().difference(last) < MapDefaults.rerouteCooldown) {
      return;
    }
    _lastRerouteAt = DateTime.now().toUtc();
    await _ensureRouteForCurrentLeg(force: true);
    _calculator.reset();
    _recalculateFromTracking();
  }

  void _listenTravelledPath() {
    unawaited(_travelledSub?.cancel());
    final service = ref.read(locationTrackingServiceProvider);
    _syncTravelledFromService();
    _travelledSub = service.acceptedLocations.listen((_) {
      if (!ref.mounted) return;
      _syncTravelledFromService();
    });
  }

  void _syncTravelledFromService() {
    final service = ref.read(locationTrackingServiceProvider);
    if (service.activeTripId != tripId) {
      state = state.copyWith(travelledPoints: const []);
      return;
    }
    state = state.copyWith(
      travelledPoints: [for (final p in service.acceptedPoints) p.asRoutePoint],
    );
  }

  void _syncLegFromTrip(Trip trip) {
    if (trip.status == TripStatus.returning && state.leg != TripLeg.returning) {
      unawaited(startReturnLeg());
    }
  }

  /// Resumes on-device phase GPS when the live map opens mid-trip.
  Future<void> _ensurePhaseTracking(Trip trip) async {
    if (!trip.status.isActivelyTracking) return;
    final service = ref.read(locationTrackingServiceProvider);
    final phase = trip.status == TripStatus.returning
        ? TripTrackPhase.returning
        : TripTrackPhase.going;
    if (service.isTracking &&
        service.activeTripId == tripId &&
        service.activePhase == phase) {
      return;
    }
    try {
      await service.startTracking(tripId: tripId, phase: phase);
    } on Object {
      // Permission issues surface via the location sharing banner.
    }
  }

  void _recalculateFromTracking() {
    final position = ref.read(locationTrackingControllerProvider).position;
    if (position == null) return;
    _updateProgress(
      RoutePoint(position.latitude, position.longitude),
      position.speed,
    );
  }

  void _updateProgress(RoutePoint position, double speedMps) {
    final endpoints = state.endpoints;
    final target = endpoints?.to.point;
    if (target == null) return;

    if (!speedMps.isNaN && speedMps > 0) {
      _recentSpeeds.add(speedMps);
      if (_recentSpeeds.length > 8) _recentSpeeds.removeAt(0);
    }
    final avgSpeed = _recentSpeeds.isEmpty
        ? null
        : _recentSpeeds.reduce((a, b) => a + b) / _recentSpeeds.length;

    final route = state.route;
    final progress = _calculator.calculate(
      polyline: route?.points ?? [position, target],
      position: position,
      target: target,
      routeDurationSeconds: route?.durationSeconds,
      recentSpeedMetersPerSecond: avgSpeed,
      straightLineFallback: route?.isApproximate ?? true,
    );
    state = state.copyWith(progress: progress);
  }

  String _pointKey(RoutePoint p) =>
      '${p.lat.toStringAsFixed(4)},${p.lng.toStringAsFixed(4)}';
}
