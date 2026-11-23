import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teletech_drivers/core/constants/api_paths.dart';
import 'package:teletech_drivers/core/network/api_exception.dart';
import 'package:teletech_drivers/features/trip_request/data/datasources/api_trip_request_remote_data_source.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request_list_bucket.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request_status.dart';

import '../../support/api_fixtures.dart';
import '../../support/scripted_api.dart';

void main() {
  late ScriptedApi api;
  late ApiTripRequestRemoteDataSource dataSource;

  setUp(() {
    api = ScriptedApi();
    dataSource = ApiTripRequestRemoteDataSource(apiClient: api.client);
  });

  group('createRequest', () {
    test('POSTs the body to trip-requests and parses the resource', () async {
      api.respondWith(ApiFixtures.tripRequest(tripId: 'trip-5'), status: 201);
      final body = {
        'pickup': {'place_id': 'place-hq'},
        'destination': {'place_id': 'place-airport'},
        'requested_at': '2026-11-03T08:00:00.000Z',
        'notes': 'hi',
      };

      final dto = await dataSource.createRequest(body);

      expect(api.last.method, 'POST');
      expect(api.last.path, ApiPaths.tripRequests);
      expect(api.last.path, 'trip-requests');
      expect(api.last.body, body);
      expect(dto.id, 'req-1');
      expect(dto.tripId, 'trip-5');
    });

    test('409 maps to ConflictApiException', () async {
      api.respondWith({'message': 'Duplicate request'}, status: 409);

      await expectLater(
        dataSource.createRequest(const {}),
        throwsA(
          isA<ConflictApiException>().having(
            (e) => e.message,
            'message',
            'Duplicate request',
          ),
        ),
      );
    });

    test('422 maps to ValidationApiException with field errors', () async {
      api.respondWith({
        'message': 'The given data was invalid.',
        'errors': {
          'pickup.name': ['Name is required'],
          'requested_at': ['Must be in the future'],
        },
      }, status: 422);

      await expectLater(
        dataSource.createRequest(const {}),
        throwsA(
          isA<ValidationApiException>()
              .having(
                (e) => e.fieldErrors['pickup.name'],
                'pickup.name',
                ['Name is required'],
              )
              .having(
                (e) => e.fieldErrors['requested_at'],
                'requested_at',
                ['Must be in the future'],
              ),
        ),
      );
    });
  });

  group('listMine', () {
    test('GETs trip-requests/mine with paging and no filters', () async {
      api.respondWith(
        paginatedPage([ApiFixtures.tripRequest(), ApiFixtures.tripRequest(id: 'req-2')]),
      );

      final result = await dataSource.listMine();

      expect(api.requests, hasLength(1));
      expect(api.last.method, 'GET');
      expect(api.last.path, 'trip-requests/mine');
      expect(api.last.query, {'page': 1, 'per_page': 100});
      expect(result.map((r) => r.id), ['req-1', 'req-2']);
    });

    test('sends the API status string', () async {
      api.respondWith(paginatedPage(const []));

      await dataSource.listMine(status: TripRequestStatus.approved);

      expect(api.last.query['status'], 'approved');
    });

    test('follows pagination until the last page', () async {
      api.respondWithHandler((options, body) async {
        final page = options.queryParameters['page'] as int;
        return jsonResponse(
          paginatedPage(
            [ApiFixtures.tripRequest(id: 'req-$page')],
            page: page,
            lastPage: 3,
          ),
        );
      });

      final result = await dataSource.listMine();

      expect(api.requests.map((r) => r.query['page']), [1, 2, 3]);
      expect(result.map((r) => r.id), ['req-1', 'req-2', 'req-3']);
    });

    test('sends bucket and awaiting_confirmation', () async {
      api.respondWith(paginatedPage(const []));

      await dataSource.listMine(
        bucket: TripRequestListBucket.active,
        awaitingConfirmation: true,
      );

      expect(api.last.query['bucket'], 'active');
      expect(api.last.query['awaiting_confirmation'], 1);
    });

    test('confirmTrip posts the report', () async {
      api.respondWith(ApiFixtures.tripRequest(id: 'req-4'));

      await dataSource.confirmTrip(
        'req-4',
        driverShowedUp: false,
        note: 'Late',
      );

      expect(api.last.method, 'POST');
      expect(api.last.path, 'trip-requests/req-4/confirm-trip');
      expect(api.last.body, {'driver_showed_up': false, 'note': 'Late'});
    });
  });

  group('listAll', () {
    test('GETs trip-requests without filters', () async {
      api.respondWith(paginatedPage([ApiFixtures.tripRequest()]));

      final result = await dataSource.listAll();

      expect(api.last.path, 'trip-requests');
      expect(api.last.query.containsKey('status'), isFalse);
      expect(api.last.query.containsKey('has_trip'), isFalse);
      expect(result, hasLength(1));
    });

    test('sends status and has_trip=0 for unassigned approved', () async {
      api.respondWith(paginatedPage(const []));

      await dataSource.listAll(
        status: TripRequestStatus.approved,
        hasTrip: false,
      );

      expect(api.last.query['status'], 'approved');
      expect(api.last.query['has_trip'], 0);
    });

    test('sends has_trip=1 when true', () async {
      api.respondWith(paginatedPage(const []));

      await dataSource.listAll(hasTrip: true);

      expect(api.last.query['has_trip'], 1);
    });

    test('malformed page envelope surfaces as FormatException', () async {
      api.respondWith({'data': 'oops'});

      await expectLater(dataSource.listAll(), throwsFormatException);
    });
  });

  group('single resource endpoints', () {
    test('getById GETs trip-requests/{id}', () async {
      api.respondWith(ApiFixtures.tripRequest(id: 'req-7'));

      final dto = await dataSource.getById('req-7');

      expect(api.last.method, 'GET');
      expect(api.last.path, 'trip-requests/req-7');
      expect(dto.id, 'req-7');
    });

    test('getById 404 maps to NotFoundApiException', () async {
      api.respondWith({'message': 'Not found'}, status: 404);

      await expectLater(
        dataSource.getById('missing'),
        throwsA(isA<NotFoundApiException>()),
      );
    });

    test('cancel POSTs trip-requests/{id}/cancel without a body', () async {
      api.respondWith(ApiFixtures.tripRequest(status: 'cancelled'));

      final dto = await dataSource.cancel('req-1');

      expect(api.last.method, 'POST');
      expect(api.last.path, 'trip-requests/req-1/cancel');
      expect(api.last.body, isNull);
      expect(dto.status, TripRequestStatus.cancelled);
    });

    test('approve POSTs trip-requests/{id}/approve without a body', () async {
      api.respondWith(ApiFixtures.tripRequest(status: 'approved'));

      final dto = await dataSource.approve('req-1');

      expect(api.last.method, 'POST');
      expect(api.last.path, 'trip-requests/req-1/approve');
      expect(api.last.body, isNull);
      expect(dto.status, TripRequestStatus.approved);
    });

    test('reject sends rejection_reason when provided', () async {
      api.respondWith(ApiFixtures.tripRequest(status: 'rejected'));

      final dto = await dataSource.reject('req-1', reason: 'No capacity');

      expect(api.last.method, 'POST');
      expect(api.last.path, 'trip-requests/req-1/reject');
      expect(api.last.body, {'rejection_reason': 'No capacity'});
      expect(dto.status, TripRequestStatus.rejected);
    });

    test('reject omits rejection_reason when null', () async {
      api.respondWith(ApiFixtures.tripRequest(status: 'rejected'));

      await dataSource.reject('req-1');

      expect(api.last.path, 'trip-requests/req-1/reject');
      expect(api.last.body, <String, dynamic>{});
    });

    test('approve 409 maps to ConflictApiException', () async {
      api.respondWith({'message': 'Already handled'}, status: 409);

      await expectLater(
        dataSource.approve('req-1'),
        throwsA(isA<ConflictApiException>()),
      );
    });

    test('reject 422 maps to ValidationApiException', () async {
      api.respondWith({
        'message': 'invalid',
        'errors': {
          'rejection_reason': ['Too long'],
        },
      }, status: 422);

      await expectLater(
        dataSource.reject('req-1', reason: 'x' * 1000),
        throwsA(
          isA<ValidationApiException>().having(
            (e) => e.fieldErrors['rejection_reason'],
            'rejection_reason',
            ['Too long'],
          ),
        ),
      );
    });

    test('cancel 409 maps to ConflictApiException', () async {
      api.respondWith({'message': 'Trip already created'}, status: 409);

      await expectLater(
        dataSource.cancel('req-1'),
        throwsA(isA<ConflictApiException>()),
      );
    });
  });

  group('approveGroup', () {
    test('POSTs request_ids and parses the data envelope', () async {
      api.respondWith({
        'data': [
          ApiFixtures.tripRequest(status: 'approved'),
          ApiFixtures.tripRequest(id: 'req-2', status: 'approved'),
        ],
      });

      final result = await dataSource.approveGroup(['req-1', 'req-2']);

      expect(api.last.method, 'POST');
      expect(api.last.path, 'trip-requests/approve-group');
      expect(api.last.body, {
        'request_ids': ['req-1', 'req-2'],
      });
      expect(result.map((r) => r.id), ['req-1', 'req-2']);
      expect(
        result.every((r) => r.status == TripRequestStatus.approved),
        isTrue,
      );
    });

    test('409 maps to ConflictApiException', () async {
      api.respondWith({'message': 'Conflict'}, status: 409);

      await expectLater(
        dataSource.approveGroup(['req-1', 'req-2']),
        throwsA(isA<ConflictApiException>()),
      );
    });

    test('422 maps to ValidationApiException', () async {
      api.respondWith({
        'message': 'invalid',
        'errors': {
          'request_ids': ['At least two requests required'],
        },
      }, status: 422);

      await expectLater(
        dataSource.approveGroup(['req-1']),
        throwsA(isA<ValidationApiException>()),
      );
    });
  });

  group('groupingSuggestions', () {
    test('GETs trip-requests/grouping-suggestions', () async {
      api.respondWith({
        'data': [
          ApiFixtures.groupSuggestion(),
          ApiFixtures.groupSuggestion(
            clusterId: 'cluster-2',
            requestIds: ['req-3', 'req-4'],
          ),
        ],
      });

      final result = await dataSource.groupingSuggestions();

      expect(api.last.method, 'GET');
      expect(api.last.path, 'trip-requests/grouping-suggestions');
      expect(result.map((s) => s.clusterId), ['cluster-1', 'cluster-2']);
      expect(result.last.requestIds, ['req-3', 'req-4']);
    });

    test('empty data yields an empty list', () async {
      api.respondWith({'data': <Object>[]});

      expect(await dataSource.groupingSuggestions(), isEmpty);
    });

    test('network timeout maps to NetworkApiException', () async {
      api.respondWithHandler((options, body) async {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionTimeout,
        );
      });

      await expectLater(
        dataSource.groupingSuggestions(),
        throwsA(isA<NetworkApiException>()),
      );
    });
  });
}
