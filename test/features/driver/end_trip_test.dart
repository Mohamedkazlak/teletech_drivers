import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:teletech_drivers/core/errors/failures.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/theme/app_theme.dart';
import 'package:teletech_drivers/features/driver/presentation/controllers/driver_trip_lifecycle_controller.dart';
import 'package:teletech_drivers/features/driver/presentation/widgets/driver_trip_list_tile.dart';
import 'package:teletech_drivers/features/drivers_admin/domain/entities/driver_recommendation.dart';
import 'package:teletech_drivers/features/place/presentation/utils/localized_place_name.dart';
import 'package:teletech_drivers/features/place/presentation/providers/place_providers.dart';
import 'package:teletech_drivers/features/tracking/domain/entities/driver_location_publish_outcome.dart';
import 'package:teletech_drivers/features/tracking/domain/entities/live_map_driver.dart';
import 'package:teletech_drivers/features/tracking/domain/entities/tracked_location_point.dart';
import 'package:teletech_drivers/features/tracking/domain/repositories/location_repository.dart';
import 'package:teletech_drivers/features/tracking/domain/services/location_tracking_service.dart';
import 'package:teletech_drivers/features/tracking/domain/use_cases/clear_tracking.dart';
import 'package:teletech_drivers/features/tracking/presentation/providers/location_tracking_service_provider.dart';
import 'package:teletech_drivers/features/tracking/presentation/providers/tracking_providers.dart';
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
import 'package:teletech_drivers/features/trip/domain/use_cases/end_trip.dart';
import 'package:teletech_drivers/features/trip/domain/use_cases/get_trip_by_id.dart';
import 'package:teletech_drivers/features/trip/presentation/providers/trip_providers.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('end keeps the API validation error and does not retry it', () async {
    final trips = _Trips()
      ..endError = const ValidationFailure(
        message: 'The given data was invalid.',
        fieldErrors: {
          'return_route': ['The return route field is required.'],
        },
      );
    final container = _container(trips);
    addTearDown(container.dispose);

    final ok = await container
        .read(driverTripLifecycleControllerProvider.notifier)
        .end('trip-1');

    final state = container.read(driverTripLifecycleControllerProvider);
    expect(ok, isFalse);
    expect(trips.endCalls, 1);
    expect(state.isLoading, isFalse);
    expect(state.activeTripId, 'trip-1');
    expect(
      state.failure,
      isA<ValidationFailure>().having(
        (failure) => failure.fieldErrors['return_route']?.single,
        'field error',
        'The return route field is required.',
      ),
    );
  });

  test(
    'end sends an empty return route when no return points were tracked',
    () async {
      final trips = _Trips();
      final container = _container(trips);
      addTearDown(container.dispose);

      final ok = await container
          .read(driverTripLifecycleControllerProvider.notifier)
          .end('trip-1');

      expect(ok, isTrue);
      expect(trips.endCalls, 1);
      expect(trips.payload?.returnRoute, isEmpty);
      expect(trips.payload?.returnDistanceMeters, 0);
      expect(trips.payload?.goingDistanceMeters, 1000);
      expect(
        container.read(driverTripLifecycleControllerProvider).failure,
        isNull,
      );
      expect(
        container.read(driverTripLifecycleControllerProvider).isLoading,
        isFalse,
      );
    },
  );

  testWidgets('End trip is enabled while returning and shows the API error', (
    tester,
  ) async {
    final trips = _Trips()
      ..endError = const ValidationFailure(
        message: 'The given data was invalid.',
        fieldErrors: {
          'return_route': ['The return route field is required.'],
        },
      );

    await tester.pumpWidget(_app(trips, _trip(TripStatus.returning)));
    await tester.pumpAndSettle();

    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'End trip'),
    );
    expect(button.onPressed, isNotNull);

    await tester.tap(find.text('End trip'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'End trip').last);
    await tester.pumpAndSettle();

    expect(trips.endCalls, 1);
    expect(
      find.textContaining('The return route field is required.'),
      findsWidgets,
    );
  });

  testWidgets('the phase button is enabled while going', (tester) async {
    await tester.pumpWidget(_app(_Trips(), _trip(TripStatus.going)));
    await tester.pumpAndSettle();

    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Arrived at destination'),
    );
    expect(button.onPressed, isNotNull);
  });
}

ProviderContainer _container(_Trips trips) {
  return ProviderContainer(
    overrides: [
      getTripByIdUseCaseProvider.overrideWithValue(GetTripByIdUseCase(trips)),
      endTripUseCaseProvider.overrideWithValue(EndTripUseCase(trips)),
      locationTrackingServiceProvider.overrideWithValue(_Tracking()),
      clearTrackingUseCaseProvider.overrideWithValue(
        ClearTrackingUseCase(_Locations()),
      ),
    ],
  );
}

Widget _app(_Trips trips, Trip trip) {
  return ProviderScope(
    overrides: [
      getTripByIdUseCaseProvider.overrideWithValue(GetTripByIdUseCase(trips)),
      endTripUseCaseProvider.overrideWithValue(EndTripUseCase(trips)),
      locationTrackingServiceProvider.overrideWithValue(_Tracking()),
      clearTrackingUseCaseProvider.overrideWithValue(
        ClearTrackingUseCase(_Locations()),
      ),
      placeNameResolverProvider.overrideWithValue(PlaceNameResolver(const [])),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: DriverTripListTile(trip: trip)),
    ),
  );
}

Trip _trip(TripStatus status) {
  return Trip(
    id: 'trip-1',
    requestIds: const [],
    passengerIds: const [],
    passengerNames: const ['Ada'],
    passengerBranches: const [],
    pickupSummary: 'HQ',
    destinationSummary: 'Site',
    scheduledAt: DateTime.utc(2026, 11, 11, 9),
    status: status,
    createdBy: 'admin',
    createdAt: DateTime.utc(2026, 11, 1),
    goingDistanceMeters: 1000,
  );
}

class _Trips implements TripRepository {
  Object? endError;
  var endCalls = 0;
  EndTripPayload? payload;

  @override
  Future<Trip?> getTripById(String tripId) async => _trip(TripStatus.returning);

  @override
  Future<void> endTrip({
    required String tripId,
    required EndTripPayload payload,
  }) async {
    endCalls++;
    this.payload = payload;
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
  Future<void> startTrip({
    required String tripId,
    required StartTripPayload payload,
  }) => throw UnimplementedError();

  @override
  Future<void> arriveAtDestination({
    required String tripId,
    required ArriveDestinationPayload payload,
  }) => throw UnimplementedError();

  @override
  Future<void> startReturn(String tripId) => throw UnimplementedError();

  @override
  Future<TripReport> getTripReport(String tripId) => throw UnimplementedError();

  @override
  Future<List<DriverRecommendation>> getDriverRecommendations(String tripId) =>
      throw UnimplementedError();
}

class _Tracking implements LocationTrackingService {
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
  Future<LocationPermissionOutcome> ensurePermissions() async =>
      LocationPermissionOutcome.granted;

  @override
  Future<void> openAppSettings() async {}

  @override
  Future<void> openLocationSettings() async {}

  @override
  Future<void> startTracking({
    required String tripId,
    required TripTrackPhase phase,
  }) async {}

  @override
  Future<void> switchPhase(TripTrackPhase phase) async {}

  @override
  Future<void> stopTracking() async {}

  @override
  PhaseTrackSnapshot finalizeCurrentPhase() => throw StateError('not tracking');

  @override
  Future<void> clearPhaseBuffer() async {}
}

class _Locations implements LocationRepository {
  @override
  Future<DriverLocationPublishOutcome> publishLocation({
    required Position position,
    String? tripId,
  }) async {
    return DriverLocationPublishOutcome.published;
  }

  @override
  Future<void> stopTracking() async {}

  @override
  Stream<List<LiveMapDriver>> watchLiveMap({String? driverId}) =>
      const Stream.empty();
}
