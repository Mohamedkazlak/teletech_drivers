import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:teletech_drivers/core/errors/failures.dart';
import 'package:teletech_drivers/core/network/api_exception.dart';
import 'package:teletech_drivers/features/tracking/data/datasources/location_remote_data_source.dart';
import 'package:teletech_drivers/features/tracking/data/models/live_map_item_dto.dart';
import 'package:teletech_drivers/features/tracking/data/repositories/api_location_repository.dart';
import 'package:teletech_drivers/features/tracking/domain/entities/driver_location_publish_outcome.dart';
import 'package:teletech_drivers/features/tracking/domain/services/location_publish_throttle.dart';
import 'package:teletech_drivers/features/tracking/domain/use_cases/publish_location.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('422 is skipped, 429 backs off, 401 is session expiry', () async {
    final source = _LocationSource();
    final repository = ApiLocationRepository(dataSource: source);
    final publish = PublishLocationUseCase(repository);

    source.error = const ValidationApiException(message: 'accuracy');
    expect(
      await publish(
        position: _position(),
        tripId: 'trip-1',
        tripInProgress: true,
      ),
      DriverLocationPublishOutcome.skipped,
    );
    expect(source.lastTripId, 'trip-1');

    source.error = const TooManyRequestsApiException(message: 'slow');
    expect(
      await publish(
        position: _position(),
        tripId: 'trip-1',
        tripInProgress: true,
      ),
      DriverLocationPublishOutcome.backedOff,
    );

    source.error = null;
    expect(
      await publish(
        position: _position(),
        tripId: 'trip-1',
        tripInProgress: false,
      ),
      DriverLocationPublishOutcome.published,
    );
    expect(source.lastTripId, isNull);

    source.error = const UnauthorizedApiException(message: 'expired');
    await expectLater(
      publish(position: _position(), tripInProgress: false),
      throwsA(isA<AuthFailure>()),
    );
  });

  test(
    'stop completes when the data source treats a missing row as success',
    () async {
      final source = _LocationSource();
      final repository = ApiLocationRepository(dataSource: source);

      await repository.stopTracking();

      expect(source.stopCalls, 1);
    },
  );

  test('heartbeat is 8 seconds, or 20 meters after the minimum gap', () {
    final throttle = LocationPublishThrottle();
    final now = DateTime.utc(2026, 11, 11, 8);

    expect(throttle.shouldSend(now, force: false), isTrue);
    throttle.recordAttempt(now);

    expect(
      throttle.shouldSend(
        now.add(const Duration(seconds: 5)),
        force: false,
        movedMeters: 25,
      ),
      isFalse,
    );
    expect(
      throttle.shouldSend(
        now.add(const Duration(seconds: 6)),
        force: false,
        movedMeters: 20,
      ),
      isTrue,
    );
    expect(
      throttle.shouldSend(
        now.add(const Duration(seconds: 7)),
        force: false,
        movedMeters: 3,
      ),
      isFalse,
    );
    expect(
      throttle.shouldSend(now.add(const Duration(seconds: 8)), force: false),
      isTrue,
    );
  });

  test('a rate-limited attempt waits for the next throttle tick', () {
    final throttle = LocationPublishThrottle(
      interval: const Duration(seconds: 15),
    );
    final now = DateTime.utc(2026, 11, 3, 8);

    expect(throttle.shouldSend(now, force: false), isTrue);
    throttle.recordAttempt(now);

    expect(
      throttle.shouldSend(now.add(const Duration(seconds: 14)), force: false),
      isFalse,
    );
    expect(
      throttle.shouldSend(now.add(const Duration(seconds: 15)), force: false),
      isTrue,
    );
  });

  test('live map polls every 20 seconds', () {
    fakeAsync((async) {
      final source = _LocationSource();
      final repository = ApiLocationRepository(dataSource: source);
      final sub = repository.watchLiveMap(driverId: 'drv-1').listen((_) {});

      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 20));
      async.flushMicrotasks();

      expect(source.liveMapCalls, 2);
      expect(source.lastLiveMapDriverId, 'drv-1');
      sub.cancel();
      repository.dispose();
    });
  });
}

class _LocationSource implements LocationRemoteDataSource {
  Object? error;
  String? lastTripId;
  int stopCalls = 0;
  int liveMapCalls = 0;
  String? lastLiveMapDriverId;

  @override
  Future<void> publish({required Position position, String? tripId}) async {
    lastTripId = tripId;
    final failure = error;
    if (failure != null) throw failure;
  }

  @override
  Future<void> stop() async {
    stopCalls += 1;
  }

  @override
  Future<List<LiveMapItemDto>> listLiveMap({String? driverId}) async {
    liveMapCalls += 1;
    lastLiveMapDriverId = driverId;
    return const [];
  }
}

Position _position() {
  return Position(
    latitude: 30,
    longitude: 31,
    timestamp: DateTime.utc(2026, 11, 3, 8),
    accuracy: 5,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 1,
    headingAccuracy: 0,
    speed: 2,
    speedAccuracy: 0,
  );
}
