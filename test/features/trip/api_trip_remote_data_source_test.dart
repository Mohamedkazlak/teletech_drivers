import 'package:flutter_test/flutter_test.dart';
import 'package:teletech_drivers/core/network/api_exception.dart';
import 'package:teletech_drivers/features/trip/data/datasources/api_trip_remote_data_source.dart';
import 'package:teletech_drivers/features/trip/domain/entities/created_trip_bucket.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_status.dart';

import '../../support/api_fixtures.dart';
import '../../support/scripted_api.dart';

void main() {
  late ScriptedApi api;
  late ApiTripRemoteDataSource dataSource;

  setUp(() {
    api = ScriptedApi();
    dataSource = ApiTripRemoteDataSource(apiClient: api.client);
  });

  group('lists', () {
    test('listTrips GETs trips with paging and no filters', () async {
      api.respondWith(
        paginatedPage([ApiFixtures.tripSummary(), ApiFixtures.tripSummary(id: 'trip-3')]),
      );

      final result = await dataSource.listTrips();

      expect(api.last.method, 'GET');
      expect(api.last.path, 'trips');
      expect(api.last.query, {'page': 1, 'per_page': 100});
      expect(result.map((t) => t.id), ['trip-2', 'trip-3']);
    });

    test('listTrips sends status and driver_id filters', () async {
      api.respondWith(paginatedPage(const []));

      await dataSource.listTrips(
        status: TripStatus.atDestination,
        driverId: 'drv-1',
      );

      expect(api.last.query['status'], 'at_destination');
      expect(api.last.query['driver_id'], 'drv-1');
    });

    test('listTrips follows pagination', () async {
      api.respondWithHandler((options, body) async {
        final page = options.queryParameters['page'] as int;
        return jsonResponse(
          paginatedPage(
            [ApiFixtures.tripSummary(id: 'trip-$page')],
            page: page,
            lastPage: 2,
          ),
        );
      });

      final result = await dataSource.listTrips();

      expect(api.requests, hasLength(2));
      expect(result.map((t) => t.id), ['trip-1', 'trip-2']);
    });

    test('listMyTrips GETs trips/mine with optional status', () async {
      api.respondWith(paginatedPage([ApiFixtures.trip()]));

      final result = await dataSource.listMyTrips(status: TripStatus.assigned);

      expect(api.last.path, 'trips/mine');
      expect(api.last.query['status'], 'assigned');
      expect(api.last.query.containsKey('driver_id'), isFalse);
      expect(result.single.driverId, 'drv-1');
    });

    test('listMyTrips sends all_assigned with a fleet period', () async {
      api.respondWith(paginatedPage(const []));

      await dataSource.listMyTrips(
        statusFilter: 'all_assigned',
        period: 'week',
        date: '2026-11-08',
      );

      expect(api.last.path, 'trips/mine');
      expect(api.last.query['status'], 'all_assigned');
      expect(api.last.query['period'], 'week');
      expect(api.last.query['date'], '2026-11-08');
    });

    test('listMyTrips without status omits the filter', () async {
      api.respondWith(paginatedPage(const []));

      await dataSource.listMyTrips();

      expect(api.last.query.containsKey('status'), isFalse);
    });

    test('drivers admin my trips GETs my-trips and not the fleet list', () async {
      api.respondWith(paginatedPage([ApiFixtures.trip()]));

      final page = await dataSource.listCreatedByMe(
        bucket: CreatedTripBucket.active,
        page: 2,
      );

      expect(api.last.method, 'GET');
      expect(api.last.path, 'my-trips');
      expect(api.last.path, isNot('trips'));
      expect(api.last.query['bucket'], 'active');
      expect(api.last.query['page'], 2);
      expect(page.data.single.id, 'trip-1');
    });
  });

  group('getTrip', () {
    test('GETs trips/{id}', () async {
      api.respondWith(ApiFixtures.trip(id: 'trip-9'));

      final dto = await dataSource.getTrip('trip-9');

      expect(api.last.method, 'GET');
      expect(api.last.path, 'trips/trip-9');
      expect(dto.id, 'trip-9');
    });

    test('404 maps to NotFoundApiException', () async {
      api.respondWith({'message': 'nope'}, status: 404);

      await expectLater(
        dataSource.getTrip('x'),
        throwsA(isA<NotFoundApiException>()),
      );
    });

    test('non-object body is rejected', () async {
      api.respondWith(<Object>[]);

      await expectLater(dataSource.getTrip('x'), throwsFormatException);
    });
  });

  group('createFromRequests', () {
    test('sends mode, request_ids and UTC scheduled_at', () async {
      api.respondWith({
        'data': [ApiFixtures.tripSummary(), ApiFixtures.tripSummary(id: 't3')],
      }, status: 201);

      final result = await dataSource.createFromRequests(
        mode: 'grouped',
        requestIds: ['req-1', 'req-2'],
        scheduledAt: DateTime.utc(2026, 11, 3, 8),
      );

      expect(api.last.method, 'POST');
      expect(api.last.path, 'trips/from-requests');
      expect(api.last.body, {
        'mode': 'grouped',
        'request_ids': ['req-1', 'req-2'],
        'scheduled_at': '2026-11-03T08:00:00.000Z',
      });
      expect(result.map((t) => t.id), ['trip-2', 't3']);
    });

    test('omits scheduled_at when null', () async {
      api.respondWith({'data': <Object>[]}, status: 201);

      await dataSource.createFromRequests(
        mode: 'one_per_request',
        requestIds: ['req-1'],
      );

      expect(api.last.body, {
        'mode': 'one_per_request',
        'request_ids': ['req-1'],
      });
    });

    test('409 maps to ConflictApiException', () async {
      api.respondWith({'message': 'Request already has a trip'}, status: 409);

      await expectLater(
        dataSource.createFromRequests(mode: 'grouped', requestIds: ['r']),
        throwsA(isA<ConflictApiException>()),
      );
    });

    test('422 maps to ValidationApiException', () async {
      api.respondWith({
        'message': 'invalid',
        'errors': {
          'scheduled_at': ['Required for grouped mode'],
        },
      }, status: 422);

      await expectLater(
        dataSource.createFromRequests(mode: 'grouped', requestIds: ['r']),
        throwsA(
          isA<ValidationApiException>().having(
            (e) => e.fieldErrors['scheduled_at'],
            'scheduled_at',
            ['Required for grouped mode'],
          ),
        ),
      );
    });
  });

  group('assignment and cancel', () {
    test('assign POSTs driver_id to trips/{id}/assign', () async {
      api.respondWith(ApiFixtures.trip());

      final dto = await dataSource.assign(tripId: 'trip-1', driverId: 'drv-1');

      expect(api.last.method, 'POST');
      expect(api.last.path, 'trips/trip-1/assign');
      expect(api.last.body, {'driver_id': 'drv-1'});
      expect(dto.status, TripStatus.assigned);
    });

    test('assign 409 and 422 map to typed exceptions', () async {
      api.respondWith({'message': 'Already assigned'}, status: 409);
      await expectLater(
        dataSource.assign(tripId: 't', driverId: 'd'),
        throwsA(isA<ConflictApiException>()),
      );

      api.respondWith({
        'message': 'invalid',
        'errors': {
          'driver_id': ['Driver is inactive'],
        },
      }, status: 422);
      await expectLater(
        dataSource.assign(tripId: 't', driverId: 'd'),
        throwsA(
          isA<ValidationApiException>().having(
            (e) => e.fieldErrors['driver_id'],
            'driver_id',
            ['Driver is inactive'],
          ),
        ),
      );
    });

    test('cancel POSTs trips/{id}/cancel without a body', () async {
      api.respondWith(ApiFixtures.trip(status: 'cancelled'));

      final dto = await dataSource.cancel('trip-1');

      expect(api.last.method, 'POST');
      expect(api.last.path, 'trips/trip-1/cancel');
      expect(api.last.body, isNull);
      expect(dto.status, TripStatus.cancelled);
    });

    test('cancel 409 maps to ConflictApiException', () async {
      api.respondWith({'message': 'Already started'}, status: 409);

      await expectLater(
        dataSource.cancel('trip-1'),
        throwsA(isA<ConflictApiException>()),
      );
    });
  });

  group('lifecycle bodies', () {
    test('start sends only start_lat and start_lng', () async {
      api.respondWith(ApiFixtures.trip(status: 'going'));

      final dto = await dataSource.start(
        tripId: 'trip-1',
        startLat: 30.01,
        startLng: 31.02,
      );

      expect(api.last.method, 'POST');
      expect(api.last.path, 'trips/trip-1/start');
      expect(api.last.body, {'start_lat': 30.01, 'start_lng': 31.02});
      expect(dto.status, TripStatus.going);
    });

    test('arrive sends going_distance_m and going_route only', () async {
      api.respondWith(ApiFixtures.trip(status: 'at_destination'));

      final dto = await dataSource.arrive(
        tripId: 'trip-1',
        goingDistanceM: 12500.5,
        goingRoute: '_p~iF~ps|U',
      );

      expect(api.last.method, 'POST');
      expect(api.last.path, 'trips/trip-1/arrive');
      expect(api.last.body, {
        'going_distance_m': 12500.5,
        'going_route': '_p~iF~ps|U',
      });
      expect(dto.status, TripStatus.atDestination);
    });

    test('startReturn POSTs trips/{id}/start-return without a body', () async {
      api.respondWith(ApiFixtures.trip(status: 'returning'));

      final dto = await dataSource.startReturn('trip-1');

      expect(api.last.method, 'POST');
      expect(api.last.path, 'trips/trip-1/start-return');
      expect(api.last.body, isNull);
      expect(dto.status, TripStatus.returning);
    });

    test('end sends return_distance_m and return_route only', () async {
      api.respondWith(ApiFixtures.trip(status: 'completed'));

      final dto = await dataSource.end(
        tripId: 'trip-1',
        returnDistanceM: 13000,
        returnRoute: '_mqNvxq`@',
      );

      expect(api.last.method, 'POST');
      expect(api.last.path, 'trips/trip-1/end');
      expect(api.last.body, {
        'return_distance_m': 13000,
        'return_route': '_mqNvxq`@',
      });
      expect(dto.status, TripStatus.completed);
    });

    test('lifecycle bodies never carry timestamps or totals', () async {
      api.respondWith(ApiFixtures.trip());
      const forbidden = {
        'going_started_at',
        'going_ended_at',
        'return_started_at',
        'finished_at',
        'scheduled_at',
        'total_distance_m',
        'total_distance_km',
        'status',
      };

      await dataSource.start(tripId: 't', startLat: 1, startLng: 2);
      await dataSource.arrive(tripId: 't', goingDistanceM: 3, goingRoute: 'r');
      await dataSource.startReturn('t');
      await dataSource.end(tripId: 't', returnDistanceM: 4, returnRoute: 'r');

      for (final request in api.requests) {
        final body = request.body;
        if (body is Map) {
          expect(
            body.keys.toSet().intersection(forbidden),
            isEmpty,
            reason: '${request.path} must not send server-owned fields',
          );
        }
      }
    });

    test('lifecycle 409 maps to ConflictApiException', () async {
      api.respondWith({'message': 'Invalid transition'}, status: 409);

      await expectLater(
        dataSource.start(tripId: 't', startLat: 1, startLng: 2),
        throwsA(isA<ConflictApiException>()),
      );
      await expectLater(
        dataSource.arrive(tripId: 't', goingDistanceM: 1, goingRoute: 'r'),
        throwsA(isA<ConflictApiException>()),
      );
      await expectLater(
        dataSource.startReturn('t'),
        throwsA(isA<ConflictApiException>()),
      );
      await expectLater(
        dataSource.end(tripId: 't', returnDistanceM: 1, returnRoute: 'r'),
        throwsA(isA<ConflictApiException>()),
      );
    });

    test('lifecycle 422 maps to ValidationApiException', () async {
      api.respondWith({
        'message': 'invalid',
        'errors': {
          'start_lat': ['Out of range'],
        },
      }, status: 422);

      await expectLater(
        dataSource.start(tripId: 't', startLat: 999, startLng: 2),
        throwsA(
          isA<ValidationApiException>().having(
            (e) => e.fieldErrors['start_lat'],
            'start_lat',
            ['Out of range'],
          ),
        ),
      );
    });

    test('403 maps to ForbiddenApiException', () async {
      api.respondWith({'message': 'Not your trip'}, status: 403);

      await expectLater(
        dataSource.startReturn('t'),
        throwsA(isA<ForbiddenApiException>()),
      );
    });
  });

  group('report and recommendations', () {
    test('getReport GETs trips/{id}/report', () async {
      api.respondWith(ApiFixtures.tripReport());

      final dto = await dataSource.getReport('trip-1');

      expect(api.last.method, 'GET');
      expect(api.last.path, 'trips/trip-1/report');
      expect(dto.status, TripStatus.completed);
      expect(dto.totalDurationSeconds, 6600);
    });

    test('getDriverRecommendations GETs trips/{id}/driver-recommendations',
        () async {
      api.respondWith({
        'data': [
          ApiFixtures.driverRecommendation(),
          ApiFixtures.driverRecommendation(driverId: 'drv-2', tier: 2),
        ],
      });

      final result = await dataSource.getDriverRecommendations('trip-1');

      expect(api.last.method, 'GET');
      expect(api.last.path, 'trips/trip-1/driver-recommendations');
      expect(result.map((r) => r.driver.id), ['drv-1', 'drv-2']);
      expect(result.last.tier, 2);
    });

    test('recommendations 404 maps to NotFoundApiException', () async {
      api.respondWith({'message': 'nope'}, status: 404);

      await expectLater(
        dataSource.getDriverRecommendations('x'),
        throwsA(isA<NotFoundApiException>()),
      );
    });

    test('5xx maps to ServerApiException', () async {
      api.respondWith({'message': 'boom'}, status: 500);

      await expectLater(
        dataSource.getReport('x'),
        throwsA(isA<ServerApiException>()),
      );
    });
  });
}
