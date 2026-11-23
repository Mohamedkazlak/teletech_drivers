import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:teletech_drivers/core/errors/failures.dart';
import 'package:teletech_drivers/features/driver/presentation/controllers/driver_trip_lifecycle_controller.dart';
import 'package:teletech_drivers/features/drivers_admin/domain/entities/driver_recommendation.dart';
import 'package:teletech_drivers/features/tracking/domain/entities/tracked_location_point.dart';
import 'package:teletech_drivers/features/tracking/domain/services/location_source.dart';
import 'package:teletech_drivers/features/tracking/domain/services/location_tracking_service.dart';
import 'package:teletech_drivers/features/tracking/presentation/controllers/location_tracking_controller.dart';
import 'package:teletech_drivers/features/tracking/presentation/providers/location_tracking_service_provider.dart';
import 'package:teletech_drivers/features/trip/data/providers/trip_repository_provider.dart';
import 'package:teletech_drivers/features/trip/domain/entities/created_trip_bucket.dart';
import 'package:teletech_drivers/features/trip/domain/entities/mine_trips_filter.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_list_query.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_page.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_phase_payload.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_report.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_status.dart';
import 'package:teletech_drivers/features/trip/domain/repositories/trip_repository.dart';
import 'package:teletech_drivers/features/trip/domain/strategies/trip_grouping_strategy.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request.dart';

void main() {
  late _Trips trips;
  late _Tracking tracking;
  late _Source source;

  setUp(() {
    trips = _Trips();
    tracking = _Tracking();
    source = _Source();
  });

  ProviderContainer container() {
    final result = ProviderContainer(
      overrides: [
        tripRepositoryProvider.overrideWithValue(trips),
        locationTrackingServiceProvider.overrideWithValue(tracking),
        locationSourceProvider.overrideWithValue(source),
        locationTrackingControllerProvider.overrideWith(_QuietTracking.new),
      ],
    );
    result.listen(driverTripLifecycleControllerProvider, (_, _) {});
    addTearDown(result.dispose);
    return result;
  }

  test('start sends the current location and clears loading', () async {
    final c = container();
    final ok = await c
        .read(driverTripLifecycleControllerProvider.notifier)
        .start('trip-1');

    expect(ok, isTrue);
    expect(trips.startCalls, 1);
    expect(trips.startPayload?.startLat, 30);
    expect(trips.startPayload?.startLng, 31);
    final state = c.read(driverTripLifecycleControllerProvider);
    expect(state.isLoading, isFalse);
    expect(state.failure, isNull);
  });

  test(
    'start does not call the API when location permission is denied',
    () async {
      tracking.permission = LocationPermissionOutcome.denied;
      final c = container();
      final ok = await c
          .read(driverTripLifecycleControllerProvider.notifier)
          .start('trip-1');

      expect(ok, isFalse);
      expect(trips.startCalls, 0);
      final state = c.read(driverTripLifecycleControllerProvider);
      expect(state.isLoading, isFalse);
      expect(
        state.failure,
        const LocationFailure(LocationErrorKind.permissionDenied),
      );
    },
  );

  test('start fails cleanly when GPS is off', () async {
    tracking.permission = LocationPermissionOutcome.servicesDisabled;
    final c = container();
    final ok = await c
        .read(driverTripLifecycleControllerProvider.notifier)
        .start('trip-1');

    expect(ok, isFalse);
    expect(trips.startCalls, 0);
    final state = c.read(driverTripLifecycleControllerProvider);
    expect(state.isLoading, isFalse);
    expect(
      state.failure,
      const LocationFailure(LocationErrorKind.servicesDisabled),
    );
  });

  test('start fails cleanly when no GPS fix is available', () async {
    source.current = null;
    final c = container();
    final ok = await c
        .read(driverTripLifecycleControllerProvider.notifier)
        .start('trip-1');

    expect(ok, isFalse);
    expect(trips.startCalls, 0);
    final state = c.read(driverTripLifecycleControllerProvider);
    expect(state.isLoading, isFalse);
    expect(state.failure, const LocationFailure(LocationErrorKind.timedOut));
  });

  test('a network error resets the loading flag', () async {
    trips.startError = const NetworkFailure();
    final c = container();
    final ok = await c
        .read(driverTripLifecycleControllerProvider.notifier)
        .start('trip-1');

    expect(ok, isFalse);
    final state = c.read(driverTripLifecycleControllerProvider);
    expect(state.isLoading, isFalse);
    expect(state.failure, isA<NetworkFailure>());
  });

  test('a status conflict becomes a friendly invalid-state failure', () async {
    trips.startError = const ConflictFailure(
      'Trip status cannot transition from going to going.',
    );
    final c = container();
    final ok = await c
        .read(driverTripLifecycleControllerProvider.notifier)
        .start('trip-1');

    expect(ok, isFalse);
    final state = c.read(driverTripLifecycleControllerProvider);
    expect(state.isLoading, isFalse);
    expect(state.failure, isA<InvalidStateFailure>());
  });

  test('a raw socket exception is not shown to the driver', () async {
    trips.startError = const ServerFailure(
      'cURL error 7: Failed to connect to 127.0.0.1:8080',
    );
    final c = container();
    final ok = await c
        .read(driverTripLifecycleControllerProvider.notifier)
        .start('trip-1');

    expect(ok, isFalse);
    final state = c.read(driverTripLifecycleControllerProvider);
    expect(state.isLoading, isFalse);
    expect(state.failure, const UnknownFailure());
  });

  test('tracking setup after a saved start does not fail the action', () async {
    tracking.startError = StateError('gps');
    final c = container();
    final ok = await c
        .read(driverTripLifecycleControllerProvider.notifier)
        .start('trip-1');

    expect(ok, isTrue);
    expect(trips.startCalls, 1);
    expect(c.read(driverTripLifecycleControllerProvider).isLoading, isFalse);
    expect(c.read(driverTripLifecycleControllerProvider).failure, isNull);
  });

  test(
    'a second start while the first is loading does not call the API',
    () async {
      trips.startGate = Completer<void>();
      final c = container();
      final first = c
          .read(driverTripLifecycleControllerProvider.notifier)
          .start('trip-1');
      await Future<void>.delayed(Duration.zero);

      final second = c
          .read(driverTripLifecycleControllerProvider.notifier)
          .start('trip-1');
      expect(await second, isFalse);
      expect(c.read(driverTripLifecycleControllerProvider).failure, isNull);
      expect(c.read(driverTripLifecycleControllerProvider).isLoading, isTrue);

      trips.startGate!.complete();
      expect(await first, isTrue);
      expect(trips.startCalls, 1);
      expect(c.read(driverTripLifecycleControllerProvider).isLoading, isFalse);
    },
  );

  test('return and end clear loading', () async {
    final c = container();
    final returned = await c
        .read(driverTripLifecycleControllerProvider.notifier)
        .startReturn('trip-1');
    expect(returned, isTrue);
    expect(trips.returnCalls, 1);
    expect(c.read(driverTripLifecycleControllerProvider).isLoading, isFalse);

    trips.endError = const ConflictFailure(
      'Trip status cannot transition from completed to completed.',
    );
    final ended = await c
        .read(driverTripLifecycleControllerProvider.notifier)
        .end('trip-1');
    expect(ended, isFalse);
    expect(c.read(driverTripLifecycleControllerProvider).isLoading, isFalse);
    expect(
      c.read(driverTripLifecycleControllerProvider).failure,
      isA<InvalidStateFailure>(),
    );
  });
}

class _QuietTracking extends LocationTrackingController {
  @override
  Future<bool> start(String tripId) async => true;

  @override
  Future<void> stop() async {}
}

class _Source implements LocationSource {
  Position? current = Position(
    latitude: 30,
    longitude: 31,
    timestamp: DateTime.utc(2026, 11, 11, 8),
    accuracy: 8,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );

  @override
  Position? get cachedPosition => null;

  @override
  Future<void> dispose() async {}

  @override
  Future<Position?> getCurrentPosition({required Duration timeout}) async =>
      current;

  @override
  Future<Position?> getLastKnownPosition() async => null;

  @override
  Stream<Position> watchPositions({required int distanceFilterMeters}) =>
      const Stream.empty();
}

class _Tracking implements LocationTrackingService {
  LocationPermissionOutcome permission = LocationPermissionOutcome.granted;
  Object? startError;

  @override
  Stream<TrackedLocationPoint> get acceptedLocations => const Stream.empty();

  @override
  String? get activeTripId => null;

  @override
  TripTrackPhase? get activePhase => null;

  @override
  bool get isTracking => false;

  @override
  List<TrackedLocationPoint> get acceptedPoints => const [];

  @override
  double get distanceMeters => 0;

  @override
  Future<LocationPermissionOutcome> ensurePermissions() async => permission;

  @override
  Future<void> openAppSettings() async {}

  @override
  Future<void> openLocationSettings() async {}

  @override
  Future<void> startTracking({
    required String tripId,
    required TripTrackPhase phase,
  }) async {
    final error = startError;
    if (error != null) throw error;
  }

  @override
  Future<void> switchPhase(TripTrackPhase phase) async {}

  @override
  Future<void> stopTracking() async {}

  @override
  PhaseTrackSnapshot finalizeCurrentPhase() => throw StateError('not tracking');

  @override
  Future<void> clearPhaseBuffer() async {}
}

class _Trips implements TripRepository {
  var startCalls = 0;
  var returnCalls = 0;
  StartTripPayload? startPayload;
  Object? startError;
  Object? endError;
  Completer<void>? startGate;

  @override
  Future<void> startTrip({
    required String tripId,
    required StartTripPayload payload,
  }) async {
    final gate = startGate;
    if (gate != null) await gate.future;
    startCalls++;
    startPayload = payload;
    final error = startError;
    if (error != null) throw error;
  }

  @override
  Future<void> startReturn(String tripId) async {
    returnCalls++;
  }

  @override
  Future<Trip?> getTripById(String tripId) async => Trip(
    id: tripId,
    requestIds: const [],
    passengerIds: const [],
    passengerNames: const ['Ada'],
    passengerBranches: const [],
    pickupSummary: 'HQ',
    destinationSummary: 'Site',
    scheduledAt: DateTime.utc(2026, 11, 11, 9),
    status: TripStatus.returning,
    createdBy: 'admin',
    createdAt: DateTime.utc(2026, 11, 1),
    goingDistanceMeters: 1000,
  );

  @override
  Future<void> endTrip({
    required String tripId,
    required EndTripPayload payload,
  }) async {
    final error = endError;
    if (error != null) throw error;
  }

  @override
  Future<List<Trip>> createTripsFromRequests({
    required List<TripRequest> requests,
    required TripGroupingStrategy strategy,
    required String createdBy,
    DateTime? scheduledAt,
  }) => throw UnimplementedError();

  @override
  Stream<List<Trip>> watchAllTrips() => throw UnimplementedError();

  @override
  Stream<List<Trip>> watchTrips(TripListQuery query) =>
      throw UnimplementedError();

  @override
  Future<TripPage> listCreatedByMe({
    required CreatedTripBucket bucket,
    required int page,
  }) => throw UnimplementedError();

  @override
  Stream<List<Trip>> watchTripsByStatus(TripStatus status) =>
      throw UnimplementedError();

  @override
  Stream<List<Trip>> watchTripsByDriver(String driverId) =>
      throw UnimplementedError();

  @override
  Stream<List<Trip>> watchMyTrips(MineTripsFilter filter) =>
      throw UnimplementedError();

  @override
  Stream<Trip?> watchTripById(String tripId) => throw UnimplementedError();

  @override
  Future<void> assignDriver({
    required String tripId,
    required String driverId,
  }) => throw UnimplementedError();

  @override
  Future<void> reassignDriver({
    required String tripId,
    required String driverId,
  }) => throw UnimplementedError();

  @override
  Future<void> cancelTrip(String tripId) => throw UnimplementedError();

  @override
  Future<void> arriveAtDestination({
    required String tripId,
    required ArriveDestinationPayload payload,
  }) => throw UnimplementedError();

  @override
  Future<TripReport> getTripReport(String tripId) => throw UnimplementedError();

  @override
  Future<List<DriverRecommendation>> getDriverRecommendations(String tripId) =>
      throw UnimplementedError();
}
