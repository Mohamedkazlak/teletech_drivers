import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:teletech_drivers/core/network/api_exception.dart';
import 'package:teletech_drivers/features/tracking/data/datasources/api_location_remote_data_source.dart';

import '../../support/scripted_api.dart';
import 'live_map_item_dto_test.dart';

void main() {
  late ScriptedApi api;
  late ApiLocationRemoteDataSource dataSource;

  setUp(() {
    api = ScriptedApi();
    dataSource = ApiLocationRemoteDataSource(apiClient: api.client);
  });

  test('PUT includes trip_id only when one is supplied', () async {
    api.respondWith(const {'driver_id': 'drv-1'});

    await dataSource.publish(position: _position(speed: 4), tripId: 'trip-1');

    expect(api.last.method, 'PUT');
    expect(api.last.path, 'driver-location');
    final withTrip = api.last.body! as Map<String, dynamic>;
    expect(withTrip['trip_id'], 'trip-1');
    expect(withTrip['lat'], 30);
    expect(withTrip['lng'], 31);
    expect(withTrip['heading'], 90);
    expect(withTrip['speed'], 4);
    expect(withTrip['accuracy'], 12);
    expect(withTrip['is_tracking'], isTrue);

    await dataSource.publish(position: _position(speed: -1));
    final withoutTrip = api.requests.last.body! as Map<String, dynamic>;
    expect(withoutTrip.containsKey('trip_id'), isFalse);
    expect(withoutTrip['speed'], 0);
  });

  test('422 surfaces as validation', () async {
    api.respondWith({
      'message': 'Accuracy too low',
      'errors': {
        'accuracy': ['too low'],
      },
    }, status: 422);

    await expectLater(
      dataSource.publish(position: _position()),
      throwsA(isA<ValidationApiException>()),
    );
  });

  test('429 surfaces as too many requests', () async {
    api.respondWith({'message': 'Slow down'}, status: 429);

    await expectLater(
      dataSource.publish(position: _position()),
      throwsA(isA<TooManyRequestsApiException>()),
    );
  });

  test('401 surfaces as unauthorized', () async {
    api.respondWith({'message': 'Unauthenticated'}, status: 401);

    await expectLater(
      dataSource.publish(position: _position()),
      throwsA(isA<UnauthorizedApiException>()),
    );
  });

  test('stop 404 is success and stop 200 posts the route', () async {
    api.respondWith({'message': 'missing'}, status: 404);
    await dataSource.stop();
    expect(api.last.method, 'POST');
    expect(api.last.path, 'driver-location/stop');

    api.respondWith(const {'driver_id': 'drv-1', 'is_tracking': false});
    await dataSource.stop();
    expect(api.requests, hasLength(2));
  });

  test('live map sends the optional driver filter', () async {
    api.respondWith({
      'data': [liveMapJson()],
    });

    final rows = await dataSource.listLiveMap(driverId: 'drv-1');

    expect(api.last.method, 'GET');
    expect(api.last.path, 'live-map');
    expect(api.last.query['driver_id'], 'drv-1');
    expect(rows.single.isStale, isFalse);

    await dataSource.listLiveMap();
    expect(api.last.query.containsKey('driver_id'), isFalse);
  });
}

Position _position({double speed = 4}) {
  return Position(
    latitude: 30,
    longitude: 31,
    timestamp: DateTime.utc(2026, 11, 3, 8),
    accuracy: 12,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 90,
    headingAccuracy: 0,
    speed: speed,
    speedAccuracy: 0,
  );
}
