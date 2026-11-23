import 'package:flutter_test/flutter_test.dart';
import 'package:teletech_drivers/core/errors/failures.dart';
import 'package:teletech_drivers/core/network/api_exception.dart';
import 'package:teletech_drivers/features/auth/domain/entities/branch.dart';
import 'package:teletech_drivers/features/trip_request/data/datasources/trip_request_remote_data_source.dart';
import 'package:teletech_drivers/features/trip_request/data/models/group_suggestion_dto.dart';
import 'package:teletech_drivers/features/trip_request/data/models/trip_request_dto.dart';
import 'package:teletech_drivers/features/trip_request/data/repositories/api_trip_request_repository.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/create_trip_request_result.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request_list_bucket.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request_stage.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request_status.dart';

import '../../support/api_fixtures.dart';

TripRequestDto _dto({
  String id = 'req-1',
  String status = 'pending',
  String? tripId,
  String requestedAt = '2026-11-03T08:00:00Z',
  String createdAt = '2026-11-02T10:00:00Z',
}) {
  return TripRequestDto.fromJson(
    ApiFixtures.tripRequest(
      id: id,
      status: status,
      tripId: tripId,
      requestedAt: requestedAt,
      createdAt: createdAt,
    ),
  );
}

class _FakeTripRequestRemote implements TripRequestRemoteDataSource {
  Map<String, dynamic>? createBody;
  TripRequestDto createResult = _dto();

  List<TripRequestDto> mineResult = const [];
  List<TripRequestDto> allResult = const [];
  final Map<String, TripRequestDto> byId = {};
  List<GroupSuggestionDto> suggestions = const [];
  Object? error;

  final calls = <String>[];
  TripRequestStatus? lastStatus;
  TripRequestListBucket? lastBucket;
  bool lastAwaitingConfirmation = false;
  bool? lastHasTrip;
  String? lastRejectReason;
  List<String>? lastApproveGroupIds;
  bool? lastConfirmShowedUp;
  String? lastConfirmNote;

  void _maybeThrow() {
    final pending = error;
    if (pending != null) throw pending;
  }

  @override
  Future<TripRequestDto> createRequest(Map<String, dynamic> body) async {
    calls.add('create');
    _maybeThrow();
    createBody = body;
    return createResult;
  }

  @override
  Future<List<TripRequestDto>> listMine({
    TripRequestStatus? status,
    TripRequestListBucket? bucket,
    bool awaitingConfirmation = false,
  }) async {
    calls.add('listMine');
    _maybeThrow();
    lastStatus = status;
    lastBucket = bucket;
    lastAwaitingConfirmation = awaitingConfirmation;
    return mineResult;
  }

  @override
  Future<TripRequestDto> confirmTrip(
    String id, {
    required bool driverShowedUp,
    String? note,
  }) async {
    calls.add('confirm:$id');
    _maybeThrow();
    lastConfirmShowedUp = driverShowedUp;
    lastConfirmNote = note;
    return _dto(id: id, status: 'approved');
  }

  @override
  Future<List<TripRequestDto>> listAll({
    TripRequestStatus? status,
    bool? hasTrip,
    Branch? branch,
    TripRequestStage? stage,
  }) async {
    calls.add('listAll');
    _maybeThrow();
    lastStatus = status;
    lastHasTrip = hasTrip;
    return allResult;
  }

  @override
  Future<TripRequestDto> getById(String id) async {
    calls.add('getById:$id');
    _maybeThrow();
    final dto = byId[id];
    if (dto == null) throw const NotFoundApiException();
    return dto;
  }

  @override
  Future<TripRequestDto> cancel(String id) async {
    calls.add('cancel:$id');
    _maybeThrow();
    return _dto(id: id, status: 'cancelled');
  }

  @override
  Future<TripRequestDto> approve(String id) async {
    calls.add('approve:$id');
    _maybeThrow();
    return _dto(id: id, status: 'approved');
  }

  @override
  Future<TripRequestDto> reject(String id, {String? reason}) async {
    calls.add('reject:$id');
    _maybeThrow();
    lastRejectReason = reason;
    return _dto(id: id, status: 'rejected');
  }

  @override
  Future<List<TripRequestDto>> approveGroup(List<String> requestIds) async {
    calls.add('approveGroup');
    _maybeThrow();
    lastApproveGroupIds = requestIds;
    return [for (final id in requestIds) _dto(id: id, status: 'approved')];
  }

  @override
  Future<List<GroupSuggestionDto>> groupingSuggestions() async {
    calls.add('groupingSuggestions');
    _maybeThrow();
    return suggestions;
  }
}

Future<CreateTripRequestResult> _create(
  ApiTripRequestRepository repository, {
  String pickupPlaceId = 'place-hq',
  String pickupPlaceName = 'HQ',
  String destinationPlaceId = 'place-airport',
  String destinationPlaceName = 'Airport',
  TripRequestStatus status = TripRequestStatus.approved,
  bool autoApproved = true,
  bool createTrip = true,
  double? pickupLat,
  double? pickupLng,
  String? pickupAddress,
  double? destinationLat,
  double? destinationLng,
  String? destinationAddress,
}) {
  return repository.createRequest(
    employeeId: 'ignored-employee',
    employeeName: 'Ignored Name',
    employeeBranch: Branch.newHeadquarters,
    employeePhone: '000',
    pickupPlaceId: pickupPlaceId,
    pickupPlaceName: pickupPlaceName,
    destinationPlaceId: destinationPlaceId,
    destinationPlaceName: destinationPlaceName,
    requestedDateTime: DateTime.utc(2026, 11, 3, 8),
    notes: 'Two bags',
    status: status,
    autoApproved: autoApproved,
    requesterRole: 'driversAdmin',
    createTrip: createTrip,
    handledByUid: 'ignored-admin',
    handledByName: 'Ignored Admin',
    pickupLat: pickupLat,
    pickupLng: pickupLng,
    pickupAddress: pickupAddress,
    destinationLat: destinationLat,
    destinationLng: destinationLng,
    destinationAddress: destinationAddress,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeTripRequestRemote remote;
  late ApiTripRequestRepository repository;

  setUp(() {
    remote = _FakeTripRequestRemote();
    repository = ApiTripRequestRepository(dataSource: remote);
  });

  tearDown(() => repository.dispose());

  group('createRequest', () {
    test('posts only pickup, destination, requested_at and notes', () async {
      await _create(repository);

      expect(remote.createBody, {
        'pickup': {'place_id': 'place-hq'},
        'destination': {'place_id': 'place-airport'},
        'requested_at': '2026-11-03T08:00:00.000Z',
        'notes': 'Two bags',
      });
    });

    test('ignores strategy fields (status, autoApproved, createTrip)', () async {
      await _create(
        repository,
        status: TripRequestStatus.pending,
        autoApproved: false,
        createTrip: false,
      );
      final pendingBody = remote.createBody;

      await _create(
        repository,
        status: TripRequestStatus.approved,
        autoApproved: true,
        createTrip: true,
      );

      expect(remote.createBody, pendingBody);
      expect(
        remote.createBody!.keys,
        unorderedEquals(['pickup', 'destination', 'requested_at', 'notes']),
      );
    });

    test('sends requested_at in UTC even for local input', () async {
      await repository.createRequest(
        employeeId: 'e',
        employeeName: 'n',
        employeeBranch: Branch.companyHeadquarters,
        employeePhone: 'p',
        pickupPlaceId: 'a',
        pickupPlaceName: 'A',
        destinationPlaceId: 'b',
        destinationPlaceName: 'B',
        requestedDateTime: DateTime(2026, 11, 3, 10),
        notes: '',
        status: TripRequestStatus.pending,
        autoApproved: false,
        requesterRole: 'employee',
        createTrip: false,
      );

      final sent = remote.createBody!['requested_at'] as String;
      expect(sent.endsWith('Z'), isTrue);
      expect(DateTime.parse(sent), DateTime(2026, 11, 3, 10).toUtc());
    });

    test('empty and custom: place ids become custom pin payloads', () async {
      await _create(
        repository,
        pickupPlaceId: '',
        pickupPlaceName: 'Pinned pickup',
        pickupLat: 30.2,
        pickupLng: 31.4,
        pickupAddress: 'Street 1',
        destinationPlaceId: 'custom:xyz',
        destinationPlaceName: 'Pinned dest',
        destinationLat: 29.9,
        destinationLng: 31.1,
      );

      expect(remote.createBody!['pickup'], {
        'name': 'Pinned pickup',
        'lat': 30.2,
        'lng': 31.4,
        'address': 'Street 1',
      });
      expect(remote.createBody!['destination'], {
        'name': 'Pinned dest',
        'lat': 29.9,
        'lng': 31.1,
      });
    });

    test('maps trip_id of a drivers-admin response', () async {
      remote.createResult = _dto(
        id: 'req-77',
        status: 'approved',
        tripId: 'trip-77',
      );

      final result = await _create(repository);

      expect(result.requestId, 'req-77');
      expect(result.tripId, 'trip-77');
    });

    test('employee response has no trip id', () async {
      remote.createResult = _dto(id: 'req-78');

      final result = await _create(repository);

      expect(result.requestId, 'req-78');
      expect(result.tripId, isNull);
    });

    test('maps API errors to failures', () async {
      remote.error = const ConflictApiException(message: 'Duplicate');
      await expectLater(
        _create(repository),
        throwsA(const ConflictFailure('Duplicate')),
      );

      remote.error = const ValidationApiException(
        message: 'bad',
        fieldErrors: {
          'pickup': ['required'],
        },
      );
      await expectLater(
        _create(repository),
        throwsA(
          const ValidationFailure(
            message: 'bad',
            fieldErrors: {
              'pickup': ['required'],
            },
          ),
        ),
      );
    });
  });

  group('moderation', () {
    test('cancelPendingRequest calls cancel with the request id', () async {
      await repository.cancelPendingRequest(
        requestId: 'req-1',
        employeeId: 'ignored',
      );
      expect(remote.calls, ['cancel:req-1']);
    });

    test('approvePendingRequest calls approve only', () async {
      await repository.approvePendingRequest(
        requestId: 'req-1',
        handledByUid: 'ignored',
        handledByName: 'ignored',
      );
      expect(remote.calls, ['approve:req-1']);
    });

    test('rejectPendingRequest forwards the reason', () async {
      await repository.rejectPendingRequest(
        requestId: 'req-1',
        handledByUid: 'ignored',
        handledByName: 'ignored',
        reason: 'No capacity',
      );
      expect(remote.calls, ['reject:req-1']);
      expect(remote.lastRejectReason, 'No capacity');
    });

    test('rejectPendingRequest without a reason sends null', () async {
      await repository.rejectPendingRequest(
        requestId: 'req-1',
        handledByUid: 'ignored',
        handledByName: 'ignored',
      );
      expect(remote.lastRejectReason, isNull);
    });

    test('approvePendingRequestsAsGroup forwards only request ids', () async {
      await repository.approvePendingRequestsAsGroup(
        requestIds: ['req-1', 'req-2'],
        suggestedGroupId: 'client-generated',
        handledByUid: 'ignored',
        handledByName: 'ignored',
      );
      expect(remote.calls, ['approveGroup']);
      expect(remote.lastApproveGroupIds, ['req-1', 'req-2']);
    });

    test('conflict on approve maps to ConflictFailure', () async {
      remote.error = const ConflictApiException(message: 'Handled already');

      await expectLater(
        repository.approvePendingRequest(
          requestId: 'r',
          handledByUid: 'u',
          handledByName: 'n',
        ),
        throwsA(const ConflictFailure('Handled already')),
      );
    });

    test('forbidden on reject maps to PermissionFailure', () async {
      remote.error = const ForbiddenApiException();

      await expectLater(
        repository.rejectPendingRequest(
          requestId: 'r',
          handledByUid: 'u',
          handledByName: 'n',
        ),
        throwsA(const PermissionFailure()),
      );
    });

    test('validation on approveGroup maps to ValidationFailure', () async {
      remote.error = const ValidationApiException(message: 'min 2');

      await expectLater(
        repository.approvePendingRequestsAsGroup(
          requestIds: ['only-one'],
          suggestedGroupId: 'g',
          handledByUid: 'u',
          handledByName: 'n',
        ),
        throwsA(isA<ValidationFailure>()),
      );
    });
  });

  group('getRequestsByIds', () {
    test('loads each id and skips missing ones', () async {
      remote.byId['req-1'] = _dto(id: 'req-1');
      remote.byId['req-3'] = _dto(id: 'req-3');

      final result = await repository.getRequestsByIds([
        'req-1',
        'req-2',
        'req-3',
      ]);

      expect(result.map((r) => r.id), ['req-1', 'req-3']);
      expect(remote.calls, ['getById:req-1', 'getById:req-2', 'getById:req-3']);
    });

    test('non-404 errors are mapped to failures', () async {
      remote.error = const NetworkApiException();

      await expectLater(
        repository.getRequestsByIds(['req-1']),
        throwsA(const NetworkFailure()),
      );
    });
  });

  group('watchRequestById', () {
    test('emits the mapped request', () async {
      remote.byId['req-1'] = _dto();

      final request = await repository.watchRequestById('req-1').first;

      expect(request?.id, 'req-1');
      expect(request?.employeeName, 'Sara Ali');
    });

    test('emits null when the request is missing', () async {
      expect(await repository.watchRequestById('missing').first, isNull);
    });

    test('emits a failure for other errors', () async {
      remote.error = const ServerApiException(message: 'boom');

      await expectLater(
        repository.watchRequestById('req-1'),
        emitsError(const ServerFailure('boom')),
      );
    });
  });

  group('list streams', () {
    test('watchEmployeeRequests uses /mine and sorts newest first', () async {
      remote.mineResult = [
        _dto(id: 'old', createdAt: '2026-11-01T10:00:00Z'),
        _dto(id: 'new', createdAt: '2026-11-03T10:00:00Z'),
        _dto(id: 'mid', createdAt: '2026-11-02T10:00:00Z'),
      ];

      final list = await repository.watchEmployeeRequests('emp-1').first;

      expect(remote.calls, ['listMine']);
      expect(list.map((r) => r.id), ['new', 'mid', 'old']);
    });

    test('watchPendingRequests filters pending, earliest requested first',
        () async {
      remote.allResult = [
        _dto(id: 'late', requestedAt: '2026-11-03T12:00:00Z'),
        _dto(id: 'early', requestedAt: '2026-11-03T07:00:00Z'),
      ];

      final list = await repository.watchPendingRequests().first;

      expect(remote.lastStatus, TripRequestStatus.pending);
      expect(remote.lastHasTrip, isNull);
      expect(list.map((r) => r.id), ['early', 'late']);
    });

    test('watchApprovedAwaitingTripRequests asks for approved without trip',
        () async {
      remote.allResult = [
        _dto(id: 'b', status: 'approved', requestedAt: '2026-11-03T09:00:00Z'),
        _dto(id: 'a', status: 'approved', requestedAt: '2026-11-03T08:00:00Z'),
      ];

      final list = await repository.watchApprovedAwaitingTripRequests().first;

      expect(remote.lastStatus, TripRequestStatus.approved);
      expect(remote.lastHasTrip, isFalse);
      expect(list.map((r) => r.id), ['a', 'b']);
    });

    test('watchAllRequests has no filters and sorts newest first', () async {
      remote.allResult = [
        _dto(id: 'old', createdAt: '2026-11-01T10:00:00Z'),
        _dto(id: 'new', createdAt: '2026-11-03T10:00:00Z'),
      ];

      final list = await repository.watchAllRequests().first;

      expect(remote.lastStatus, isNull);
      expect(remote.lastHasTrip, isNull);
      expect(list.map((r) => r.id), ['new', 'old']);
    });

    test('list stream errors are mapped to failures', () async {
      remote.error = const NetworkApiException();

      await expectLater(
        repository.watchAllRequests(),
        emitsError(const NetworkFailure()),
      );
    });
  });

  group('getGroupingSuggestions', () {
    GroupSuggestionDto suggestion(String id, List<String> ids) {
      return GroupSuggestionDto.fromJson(
        ApiFixtures.groupSuggestion(clusterId: id, requestIds: ids),
      );
    }

    test('joins suggestions with known requests', () async {
      remote.allResult = [
        _dto(id: 'req-1', requestedAt: '2026-11-03T09:00:00Z'),
        _dto(id: 'req-2', requestedAt: '2026-11-03T08:00:00Z'),
        _dto(id: 'req-3'),
      ];
      final knownRequests = await repository.watchAllRequests().first;
      remote.suggestions = [suggestion('c1', ['req-1', 'req-2'])];

      final result = await repository.getGroupingSuggestions(
        knownRequests: knownRequests,
      );

      expect(result, hasLength(1));
      expect(result.single.clusterId, 'c1');
      expect(result.single.requests.map((r) => r.id), ['req-2', 'req-1']);
      expect(result.single.routeLabel, 'HQ → Airport');
    });

    test('drops clusters whose members are not all loaded', () async {
      remote.allResult = [_dto(id: 'req-1'), _dto(id: 'req-2')];
      final knownRequests = await repository.watchAllRequests().first;
      remote.suggestions = [
        suggestion('c1', ['req-1', 'req-2']),
        suggestion('c2', ['req-1', 'missing']),
        suggestion('c3', ['unknown-a', 'unknown-b']),
      ];

      final result = await repository.getGroupingSuggestions(
        knownRequests: knownRequests,
      );

      expect(result.map((s) => s.clusterId), ['c1']);
    });

    test('empty known requests yields no suggestions', () async {
      remote.suggestions = [suggestion('c1', ['req-1', 'req-2'])];

      expect(
        await repository.getGroupingSuggestions(knownRequests: const []),
        isEmpty,
      );
    });

    test('maps API errors to failures', () async {
      remote.error = const ForbiddenApiException();

      await expectLater(
        repository.getGroupingSuggestions(knownRequests: const []),
        throwsA(const PermissionFailure()),
      );
    });
  });
}
