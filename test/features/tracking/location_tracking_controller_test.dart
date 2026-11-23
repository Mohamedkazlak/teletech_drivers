import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:teletech_drivers/core/errors/failures.dart';
import 'package:teletech_drivers/features/tracking/domain/entities/driver_location_publish_outcome.dart';
import 'package:teletech_drivers/features/tracking/domain/entities/live_map_driver.dart';
import 'package:teletech_drivers/features/tracking/domain/repositories/location_repository.dart';
import 'package:teletech_drivers/features/tracking/domain/use_cases/clear_tracking.dart';
import 'package:teletech_drivers/features/tracking/domain/use_cases/publish_location.dart';
import 'package:teletech_drivers/features/tracking/presentation/controllers/location_tracking_controller.dart';
import 'package:teletech_drivers/features/tracking/presentation/providers/tracking_providers.dart';
import 'package:teletech_drivers/features/tracking/presentation/state/location_tracking_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a skipped or backed-off sample does not raise an error banner', () async {
    final repository = _LocationRepository();
    final container = _container(repository);
    addTearDown(container.dispose);

    repository.outcome = DriverLocationPublishOutcome.skipped;
    await container
        .read(locationTrackingControllerProvider.notifier)
        .handlePositionForTest(_position(accuracy: 8), tripId: 'trip-1');

    expect(repository.tripIds, ['trip-1']);
    expect(container.read(locationTrackingControllerProvider).failure, isNull);
    expect(
      container.read(locationTrackingControllerProvider).warningBanner,
      isFalse,
    );

    repository.outcome = DriverLocationPublishOutcome.backedOff;
    await container
        .read(locationTrackingControllerProvider.notifier)
        .handlePositionForTest(_position(accuracy: 8), tripId: 'trip-1');

    expect(
      container.read(locationTrackingControllerProvider).status,
      isNot(LocationTrackingStatus.error),
    );
    expect(container.read(locationTrackingControllerProvider).failure, isNull);
  });

  test('a failed publish keeps the point and shows an error', () async {
    final repository = _LocationRepository();
    final container = _container(repository);
    addTearDown(container.dispose);

    repository.error = const NetworkFailure();
    await container
        .read(locationTrackingControllerProvider.notifier)
        .handlePositionForTest(_position(), tripId: 'trip-1');

    final state = container.read(locationTrackingControllerProvider);
    expect(state.failure, isA<NetworkFailure>());
    expect(state.warningBanner, isTrue);
    expect(state.position?.latitude, 30);
    expect(state.status, LocationTrackingStatus.sharing);
  });

  test('stop on trip end calls the stop endpoint and stays idle', () async {
    final repository = _LocationRepository();
    final container = _container(repository);
    addTearDown(container.dispose);

    await container.read(locationTrackingControllerProvider.notifier).stop();

    expect(repository.stops, 1);
    expect(
      container.read(locationTrackingControllerProvider).status,
      LocationTrackingStatus.idle,
    );
    expect(container.read(locationTrackingControllerProvider).failure, isNull);
  });
}

ProviderContainer _container(_LocationRepository repository) {
  final publish = PublishLocationUseCase(repository);
  final clear = ClearTrackingUseCase(repository);
  return ProviderContainer(
    overrides: [
      publishLocationUseCaseProvider.overrideWithValue(publish),
      clearTrackingUseCaseProvider.overrideWithValue(clear),
    ],
  );
}

Position _position({double accuracy = 8}) {
  return Position(
    latitude: 30,
    longitude: 31,
    timestamp: DateTime.utc(2026, 11, 3, 8),
    accuracy: accuracy,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 10,
    headingAccuracy: 0,
    speed: 3,
    speedAccuracy: 0,
  );
}

class _LocationRepository implements LocationRepository {
  DriverLocationPublishOutcome outcome = DriverLocationPublishOutcome.published;
  Object? error;
  final tripIds = <String?>[];
  var stops = 0;

  @override
  Future<DriverLocationPublishOutcome> publishLocation({
    required Position position,
    String? tripId,
  }) async {
    final thrown = error;
    if (thrown != null) throw thrown;
    tripIds.add(tripId);
    return outcome;
  }

  @override
  Future<void> stopTracking() async {
    stops += 1;
  }

  @override
  Stream<List<LiveMapDriver>> watchLiveMap({String? driverId}) =>
      const Stream.empty();
}
