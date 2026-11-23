import 'package:flutter_test/flutter_test.dart';
import 'package:teletech_drivers/core/errors/failures.dart';
import 'package:teletech_drivers/core/network/api_exception.dart';
import 'package:teletech_drivers/core/network/paginated_response.dart';
import 'package:teletech_drivers/features/auth/domain/entities/branch.dart';
import 'package:teletech_drivers/features/drivers_admin/domain/entities/driver_recommendation.dart';
import 'package:teletech_drivers/features/tracking/domain/entities/route_point.dart';
import 'package:teletech_drivers/features/tracking/domain/services/polyline_encoder.dart';
import 'package:teletech_drivers/features/trip/data/datasources/trip_remote_data_source.dart';
import 'package:teletech_drivers/features/trip/data/models/driver_recommendation_dto.dart';
import 'package:teletech_drivers/features/trip/data/models/trip_dto.dart';
import 'package:teletech_drivers/features/trip/data/models/trip_report_dto.dart';
import 'package:teletech_drivers/features/trip/data/repositories/api_trip_repository.dart';
import 'package:teletech_drivers/features/trip/domain/entities/created_trip_bucket.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_phase_payload.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_lifecycle.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_stage.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_status.dart';
import 'package:teletech_drivers/features/trip/domain/strategies/grouped_requests.dart';
import 'package:teletech_drivers/features/trip/domain/strategies/one_request_per_trip.dart';
import 'package:teletech_drivers/features/trip_request/data/mappers/trip_request_dto_mapper.dart';
import 'package:teletech_drivers/features/trip_request/data/models/trip_request_dto.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request.dart';

import '../../support/api_fixtures.dart';

TripDto _trip({
  String id = 'trip-1',
  String status = 'assigned',
  String? driverId = 'drv-1',
  String scheduledAt = '2026-11-03T08:00:00Z',
  String createdAt = '2026-11-02T10:00:00Z',
}) {
  return TripDto.fromJson(
    ApiFixtures.trip(id: id, status: status, driverId: driverId)
      ..['scheduled_at'] = scheduledAt
      ..['created_at'] = createdAt,
  );
}

TripRequest _request(String id, {String requestedAt = '2026-11-03T08:00:00Z'}) {
  return TripRequestDtoMapper.toEntity(
    TripRequestDto.fromJson(
      ApiFixtures.tripRequest(
        id: id,
        employeeId: 'emp-$id',
        status: 'approved',
        requestedAt: requestedAt,
      ),
    ),
  );
}

class _FakeTripRemote implements TripRemoteDataSource {
  List<TripDto> listResult = const [];
  List<TripDto> mineResult = const [];
  final Map<String, TripDto> byId = {};
  TripReportDto reportResult = TripReportDto.fromJson(ApiFixtures.tripReport());
  List<DriverRecommendationDto> recommendations = const [];
  Object? error;

  final calls = <String>[];
  TripStatus? lastStatus;
  String? lastDriverFilter;

  String? createMode;
  List<String>? createRequestIds;
  DateTime? createScheduledAt;
  String? assignedDriverId;
  Map<String, Object?>? lifecycleArgs;

  void _maybeThrow() {
    final pending = error;
    if (pending != null) throw pending;
  }

  @override
  Future<List<TripDto>> listTrips({
    TripStatus? status,
    String? driverId,
    TripStage? stage,
    Branch? branch,
    TripLifecycle? lifecycle,
  }) async {
    calls.add('listTrips');
    _maybeThrow();
    lastStatus = status;
    lastDriverFilter = driverId;
    return listResult;
  }

  @override
  Future<PaginatedResponse<TripDto>> listCreatedByMe({
    required CreatedTripBucket bucket,
    required int page,
  }) async {
    calls.add('listCreatedByMe');
    return PaginatedResponse(
      data: const [],
      currentPage: page,
      lastPage: page,
      perPage: 15,
      total: 0,
    );
  }

  @override
  Future<List<TripDto>> listMyTrips({
    TripStatus? status,
    String? statusFilter,
    String? period,
    String? date,
  }) async {
    calls.add('listMyTrips');
    _maybeThrow();
    lastStatus = status;
    return mineResult;
  }

  @override
  Future<TripDto> getTrip(String tripId) async {
    calls.add('getTrip:$tripId');
    _maybeThrow();
    final dto = byId[tripId];
    if (dto == null) throw const NotFoundApiException();
    return dto;
  }

  @override
  Future<List<TripDto>> createFromRequests({
    required String mode,
    required List<String> requestIds,
    DateTime? scheduledAt,
  }) async {
    calls.add('createFromRequests');
    _maybeThrow();
    createMode = mode;
    createRequestIds = requestIds;
    createScheduledAt = scheduledAt;
    return [_trip()];
  }

  @override
  Future<TripDto> assign({
    required String tripId,
    required String driverId,
  }) async {
    calls.add('assign:$tripId');
    _maybeThrow();
    assignedDriverId = driverId;
    return _trip(id: tripId);
  }

  @override
  Future<TripDto> cancel(String tripId) async {
    calls.add('cancel:$tripId');
    _maybeThrow();
    return _trip(id: tripId, status: 'cancelled');
  }

  @override
  Future<TripDto> start({
    required String tripId,
    required double startLat,
    required double startLng,
  }) async {
    calls.add('start:$tripId');
    _maybeThrow();
    lifecycleArgs = {'startLat': startLat, 'startLng': startLng};
    return _trip(id: tripId, status: 'going');
  }

  @override
  Future<TripDto> arrive({
    required String tripId,
    required double goingDistanceM,
    required String goingRoute,
  }) async {
    calls.add('arrive:$tripId');
    _maybeThrow();
    lifecycleArgs = {
      'goingDistanceM': goingDistanceM,
      'goingRoute': goingRoute,
    };
    return _trip(id: tripId, status: 'at_destination');
  }

  @override
  Future<TripDto> startReturn(String tripId) async {
    calls.add('startReturn:$tripId');
    _maybeThrow();
    lifecycleArgs = const {};
    return _trip(id: tripId, status: 'returning');
  }

  @override
  Future<TripDto> end({
    required String tripId,
    required double returnDistanceM,
    required String returnRoute,
  }) async {
    calls.add('end:$tripId');
    _maybeThrow();
    lifecycleArgs = {
      'returnDistanceM': returnDistanceM,
      'returnRoute': returnRoute,
    };
    return _trip(id: tripId, status: 'completed');
  }

  @override
  Future<TripReportDto> getReport(String tripId) async {
    calls.add('getReport:$tripId');
    _maybeThrow();
    return reportResult;
  }

  @override
  Future<List<DriverRecommendationDto>> getDriverRecommendations(
    String tripId,
  ) async {
    calls.add('getDriverRecommendations:$tripId');
    _maybeThrow();
    return recommendations;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeTripRemote remote;
  late ApiTripRepository repository;

  setUp(() {
    remote = _FakeTripRemote();
    repository = ApiTripRepository(dataSource: remote);
  });

  tearDown(() => repository.dispose());

  group('createTripsFromRequests', () {
    test('one-per-request strategy posts mode and ids without schedule',
        () async {
      await repository.createTripsFromRequests(
        requests: [_request('r1'), _request('r2')],
        strategy: const OneRequestPerTrip(),
        createdBy: 'ignored-admin',
      );

      expect(remote.calls, ['createFromRequests']);
      expect(remote.createMode, 'one_per_request');
      expect(remote.createRequestIds, ['r1', 'r2']);
      expect(remote.createScheduledAt, isNull);
    });

    test('grouped strategy posts grouped mode with scheduled time', () async {
      final scheduledAt = DateTime.utc(2026, 11, 3, 9, 30);

      await repository.createTripsFromRequests(
        requests: [_request('r1'), _request('r2'), _request('r3')],
        strategy: const GroupedRequests(),
        createdBy: 'ignored-admin',
        scheduledAt: scheduledAt,
      );

      expect(remote.createMode, 'grouped');
      expect(remote.createRequestIds, ['r1', 'r2', 'r3']);
      expect(remote.createScheduledAt, scheduledAt);
    });

    test('empty selection is an InvalidStateFailure and sends nothing',
        () async {
      await expectLater(
        repository.createTripsFromRequests(
          requests: const [],
          strategy: const OneRequestPerTrip(),
          createdBy: 'admin',
        ),
        throwsA(const InvalidStateFailure()),
      );
      expect(remote.calls, isEmpty);
    });

    test('maps conflict and validation errors', () async {
      remote.error = const ConflictApiException(message: 'Has a trip');
      await expectLater(
        repository.createTripsFromRequests(
          requests: [_request('r1')],
          strategy: const OneRequestPerTrip(),
          createdBy: 'admin',
        ),
        throwsA(const ConflictFailure('Has a trip')),
      );

      remote.error = const ValidationApiException(message: 'bad');
      await expectLater(
        repository.createTripsFromRequests(
          requests: [_request('r1')],
          strategy: const OneRequestPerTrip(),
          createdBy: 'admin',
        ),
        throwsA(const ValidationFailure(message: 'bad')),
      );
    });
  });

  group('assign / reassign / cancel', () {
    test('assignDriver forwards trip and driver ids', () async {
      await repository.assignDriver(tripId: 'trip-1', driverId: 'drv-9');

      expect(remote.calls, ['assign:trip-1']);
      expect(remote.assignedDriverId, 'drv-9');
    });

    test('reassignDriver uses the same assign endpoint', () async {
      await repository.reassignDriver(tripId: 'trip-1', driverId: 'drv-2');

      expect(remote.calls, ['assign:trip-1']);
      expect(remote.assignedDriverId, 'drv-2');
    });

    test('cancelTrip calls cancel', () async {
      await repository.cancelTrip('trip-1');
      expect(remote.calls, ['cancel:trip-1']);
    });

    test('assign conflict maps to ConflictFailure', () async {
      remote.error = const ConflictApiException(message: 'Taken');

      await expectLater(
        repository.assignDriver(tripId: 't', driverId: 'd'),
        throwsA(const ConflictFailure('Taken')),
      );
    });

    test('cancel conflict maps to ConflictFailure', () async {
      remote.error = const ConflictApiException();

      await expectLater(
        repository.cancelTrip('t'),
        throwsA(isA<ConflictFailure>()),
      );
    });
  });

  group('lifecycle', () {
    test('startTrip forwards only start coordinates', () async {
      await repository.startTrip(
        tripId: 'trip-1',
        payload: const StartTripPayload(startLat: 30.01, startLng: 31.02),
      );

      expect(remote.calls, ['start:trip-1']);
      expect(remote.lifecycleArgs, {'startLat': 30.01, 'startLng': 31.02});
    });

    test('arriveAtDestination forwards only going distance and route',
        () async {
      await repository.arriveAtDestination(
        tripId: 'trip-1',
        payload: const ArriveDestinationPayload(
          goingRoute: 'route-going',
          goingDistanceMeters: 12500.5,
        ),
      );

      expect(remote.calls, ['arrive:trip-1']);
      expect(remote.lifecycleArgs, {
        'goingDistanceM': 12500.5,
        'goingRoute': 'route-going',
      });
    });

    test('startReturn forwards only the trip id', () async {
      await repository.startReturn('trip-1');

      expect(remote.calls, ['startReturn:trip-1']);
      expect(remote.lifecycleArgs, isEmpty);
    });

    test('endTrip forwards only return distance and route (no totals)',
        () async {
      await repository.endTrip(
        tripId: 'trip-1',
        payload: const EndTripPayload(
          returnRoute: 'route-return',
          returnDistanceMeters: 13000,
          goingDistanceMeters: 12500.5,
        ),
      );

      expect(remote.calls, ['end:trip-1']);
      expect(remote.lifecycleArgs, {
        'returnDistanceM': 13000.0,
        'returnRoute': 'route-return',
      });
      expect(remote.lifecycleArgs!.containsKey('goingDistanceM'), isFalse);
      expect(remote.lifecycleArgs!.containsKey('totalDistanceM'), isFalse);
    });

    test('lifecycle errors map to failures', () async {
      remote.error = const ConflictApiException(message: 'Bad transition');
      const start = StartTripPayload(startLat: 1, startLng: 2);

      await expectLater(
        repository.startTrip(tripId: 't', payload: start),
        throwsA(const ConflictFailure('Bad transition')),
      );
      await expectLater(
        repository.startReturn('t'),
        throwsA(isA<ConflictFailure>()),
      );

      remote.error = const ValidationApiException(message: 'bad');
      await expectLater(
        repository.endTrip(
          tripId: 't',
          payload: const EndTripPayload(
            returnRoute: 'r',
            returnDistanceMeters: 1,
            goingDistanceMeters: 1,
          ),
        ),
        throwsA(isA<ValidationFailure>()),
      );
    });
  });

  group('getTripById', () {
    test('maps the trip', () async {
      remote.byId['trip-1'] = _trip();

      final trip = await repository.getTripById('trip-1');

      expect(trip?.id, 'trip-1');
      expect(trip?.requestIds, ['req-1']);
    });

    test('404 becomes null', () async {
      expect(await repository.getTripById('missing'), isNull);
    });

    test('other errors map to failures', () async {
      remote.error = const ServerApiException(message: 'boom');

      await expectLater(
        repository.getTripById('trip-1'),
        throwsA(const ServerFailure('boom')),
      );
    });
  });

  group('watch streams', () {
    test('watchAllTrips lists all trips newest first', () async {
      remote.listResult = [
        _trip(id: 'old', createdAt: '2026-11-01T10:00:00Z'),
        _trip(id: 'new', createdAt: '2026-11-03T10:00:00Z'),
      ];

      final list = await repository.watchAllTrips().first;

      expect(remote.lastStatus, isNull);
      expect(list.map((t) => t.id), ['new', 'old']);
    });

    test('watchTripsByStatus passes the status filter', () async {
      remote.listResult = [_trip(status: 'going')];

      final list =
          await repository.watchTripsByStatus(TripStatus.going).first;

      expect(remote.lastStatus, TripStatus.going);
      expect(list.single.status, TripStatus.going);
    });

    test('watchTripsByDriver uses /mine, filters driver, sorts by schedule',
        () async {
      remote.mineResult = [
        _trip(id: 'late', scheduledAt: '2026-11-03T12:00:00Z'),
        _trip(id: 'other', driverId: 'drv-2'),
        _trip(id: 'early', scheduledAt: '2026-11-03T07:00:00Z'),
      ];

      final list = await repository.watchTripsByDriver('drv-1').first;

      expect(remote.calls, ['listMyTrips']);
      expect(list.map((t) => t.id), ['early', 'late']);
    });

    test('watchTripById emits trip then null for missing', () async {
      remote.byId['trip-1'] = _trip();

      expect((await repository.watchTripById('trip-1').first)?.id, 'trip-1');
      expect(await repository.watchTripById('missing').first, isNull);
    });

    test('list stream errors are mapped to failures', () async {
      remote.error = const NetworkApiException();

      await expectLater(
        repository.watchAllTrips(),
        emitsError(const NetworkFailure()),
      );
    });

    test('detail stream errors are mapped to failures', () async {
      remote.error = const ForbiddenApiException();

      await expectLater(
        repository.watchTripById('trip-1'),
        emitsError(const PermissionFailure()),
      );
    });
  });

  group('getTripReport', () {
    test('maps the report DTO with durations and polyline points', () async {
      remote.reportResult = TripReportDto.fromJson(
        ApiFixtures.tripReport()
          ..['going_route'] = PolylineEncoder.encode(const [
            RoutePoint(30.0, 31.0),
            RoutePoint(30.1, 31.1),
          ]),
      );

      final report = await repository.getTripReport('trip-1');

      expect(remote.calls, ['getReport:trip-1']);
      expect(report.status, TripStatus.completed);
      expect(report.totalDuration, const Duration(seconds: 6600));
      expect(report.goingDistanceKm, 12.5);
      expect(report.goingPoints, hasLength(2));
      expect(report.hasRouteGeometry, isTrue);
    });

    test('errors map to failures', () async {
      remote.error = const NotFoundApiException();

      await expectLater(
        repository.getTripReport('x'),
        throwsA(const NotFoundFailure()),
      );
    });
  });

  group('getDriverRecommendations', () {
    test('maps every recommendation in server order', () async {
      remote.recommendations = [
        DriverRecommendationDto.fromJson(
          ApiFixtures.driverRecommendation(driverId: 'drv-1', tier: 0),
        ),
        DriverRecommendationDto.fromJson(
          ApiFixtures.driverRecommendation(
            driverId: 'drv-2',
            tier: 3,
            isUnavailable: true,
          ),
        ),
      ];

      final result = await repository.getDriverRecommendations('trip-1');

      expect(remote.calls, ['getDriverRecommendations:trip-1']);
      expect(result.map((r) => r.driver.id), ['drv-1', 'drv-2']);
      expect(result.first.isRecommended, isTrue);
      expect(result.last.isRecommended, isFalse);
      expect(result.last.reasons, contains(DriverRecommendationReason.unavailable));
    });

    test('empty list passes through', () async {
      expect(await repository.getDriverRecommendations('trip-1'), isEmpty);
    });

    test('errors map to failures', () async {
      remote.error = const ForbiddenApiException();

      await expectLater(
        repository.getDriverRecommendations('trip-1'),
        throwsA(const PermissionFailure()),
      );
    });
  });
}
