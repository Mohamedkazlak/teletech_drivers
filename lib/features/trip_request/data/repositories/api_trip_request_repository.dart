import 'package:teletech_drivers/core/constants/api_json_keys.dart';
import 'package:teletech_drivers/core/constants/polling_intervals.dart';
import 'package:teletech_drivers/core/errors/failures.dart';
import 'package:teletech_drivers/core/network/api_exception.dart';
import 'package:teletech_drivers/core/network/api_failure_mapper.dart';
import 'package:teletech_drivers/core/polling/polling_stream.dart';
import 'package:teletech_drivers/features/auth/domain/entities/branch.dart';
import 'package:teletech_drivers/features/trip_request/data/datasources/trip_request_remote_data_source.dart';
import 'package:teletech_drivers/features/trip_request/data/mappers/trip_request_dto_mapper.dart';
import 'package:teletech_drivers/features/trip_request/data/models/place_snapshot_dto.dart';
import 'package:teletech_drivers/features/trip_request/data/models/trip_request_dto.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/create_trip_request_result.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/group_suggestion.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request_list_query.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request_list_bucket.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request_status.dart';
import 'package:teletech_drivers/features/trip_request/domain/repositories/trip_request_repository.dart';

/// Repository: Laravel trip-requests API with polling streams.
class ApiTripRequestRepository implements TripRequestRepository {
  ApiTripRequestRepository({
    required this.dataSource,
    this.failureMapper = const ApiFailureMapper(),
  });

  final TripRequestRemoteDataSource dataSource;
  final ApiFailureMapper failureMapper;

  final _listPolling = <PollingStream<List<TripRequest>>>[];
  final _detailPolling = <PollingStream<TripRequest?>>[];

  @override
  Future<CreateTripRequestResult> createRequest({
    required String employeeId,
    required String employeeName,
    required Branch employeeBranch,
    required String employeePhone,
    required String pickupPlaceId,
    required String pickupPlaceName,
    required String destinationPlaceId,
    required String destinationPlaceName,
    required DateTime requestedDateTime,
    required String notes,
    required TripRequestStatus status,
    required bool autoApproved,
    required String requesterRole,
    required bool createTrip,
    String? handledByUid,
    String? handledByName,
    double? pickupLat,
    double? pickupLng,
    String? pickupAddress,
    double? destinationLat,
    double? destinationLng,
    String? destinationAddress,
  }) {
    // status / autoApproved / createTrip / handledBy* / employee snapshot are
    // intentionally ignored: the server derives them from the authenticated user.
    return _guardValue(() async {
      final pickup = PlaceSnapshotDto(
        placeId: _nonEmpty(pickupPlaceId),
        name: pickupPlaceName,
        lat: pickupLat,
        lng: pickupLng,
        address: pickupAddress,
      );
      final destination = PlaceSnapshotDto(
        placeId: _nonEmpty(destinationPlaceId),
        name: destinationPlaceName,
        lat: destinationLat,
        lng: destinationLng,
        address: destinationAddress,
      );
      final dto = await dataSource.createRequest({
        ApiJsonKeys.pickup: pickup.toCreateBody(),
        ApiJsonKeys.destination: destination.toCreateBody(),
        ApiJsonKeys.requestedAt: requestedDateTime.toUtc().toIso8601String(),
        ApiJsonKeys.notes: notes,
      });
      return CreateTripRequestResult(requestId: dto.id, tripId: dto.tripId);
    });
  }

  @override
  Stream<List<TripRequest>> watchEmployeeRequests(String employeeId) {
    // `/mine` is scoped to the authenticated user; [employeeId] is not sent.
    return _watchList(() async {
      final requests = _toRequests(await dataSource.listMine());
      return requests..sort(_newestFirst);
    });
  }

  @override
  Stream<List<TripRequest>> watchMyRequests({TripRequestListBucket? bucket}) {
    return _watchList(() async {
      final requests = _toRequests(await dataSource.listMine(bucket: bucket));
      return requests..sort(_newestFirst);
    });
  }

  @override
  Stream<List<TripRequest>> watchAwaitingConfirmation() {
    return _watchList(() async {
      final requests = _toRequests(
        await dataSource.listMine(awaitingConfirmation: true),
      );
      return requests..sort(_newestFirst);
    });
  }

  @override
  Future<TripRequest> confirmTrip({
    required String requestId,
    required bool driverShowedUp,
    String? note,
  }) {
    return _guardValue(() async {
      final trimmed = note?.trim();
      final dto = await dataSource.confirmTrip(
        requestId,
        driverShowedUp: driverShowedUp,
        note: trimmed == null || trimmed.isEmpty ? null : trimmed,
      );
      return TripRequestDtoMapper.toEntity(dto);
    });
  }

  @override
  Stream<TripRequest?> watchRequestById(String requestId) {
    final polling = PollingStream<TripRequest?>(
      fetch: () => _guardValue(() => _loadRequest(requestId)),
      interval: PollingIntervals.tripDetails,
    );
    _detailPolling.add(polling);
    return polling.stream.handleError((Object error, StackTrace stackTrace) {
      Error.throwWithStackTrace(_toFailure(error), stackTrace);
    });
  }

  @override
  Stream<List<TripRequest>> watchPendingRequests() {
    return _watchList(() async {
      final requests = _toRequests(
        await dataSource.listAll(status: TripRequestStatus.pending),
      );
      return requests..sort(_earliestRequestedFirst);
    });
  }

  @override
  Stream<List<TripRequest>> watchApprovedAwaitingTripRequests() {
    return _watchList(() async {
      final requests = _toRequests(
        await dataSource.listAll(
          status: TripRequestStatus.approved,
          hasTrip: false,
        ),
      );
      return requests..sort(_earliestRequestedFirst);
    });
  }

  @override
  Stream<List<TripRequest>> watchAllRequests() {
    return watchRequests(const TripRequestListQuery());
  }

  @override
  Stream<List<TripRequest>> watchRequests(TripRequestListQuery query) {
    return _watchList(() async {
      final requests = _toRequests(
        await dataSource.listAll(
          status: query.status,
          branch: query.branch,
          stage: query.stage,
        ),
      );
      return requests..sort(_newestFirst);
    });
  }

  @override
  Future<List<TripRequest>> getRequestsByIds(List<String> requestIds) {
    return _guardValue(() async {
      final loaded = await Future.wait([
        for (final id in requestIds) _loadRequest(id),
      ]);
      return [for (final request in loaded) ?request];
    });
  }

  @override
  Future<void> cancelPendingRequest({
    required String requestId,
    required String employeeId,
  }) {
    return _guard(() => dataSource.cancel(requestId));
  }

  @override
  Future<void> approvePendingRequest({
    required String requestId,
    required String handledByUid,
    required String handledByName,
  }) {
    return _guard(() => dataSource.approve(requestId));
  }

  @override
  Future<void> approvePendingRequestsAsGroup({
    required List<String> requestIds,
    required String suggestedGroupId,
    required String handledByUid,
    required String handledByName,
  }) {
    // suggestedGroupId / handledBy* are generated server-side.
    return _guard(() => dataSource.approveGroup(requestIds));
  }

  @override
  Future<void> rejectPendingRequest({
    required String requestId,
    required String handledByUid,
    required String handledByName,
    String? reason,
  }) {
    return _guard(() => dataSource.reject(requestId, reason: reason));
  }

  @override
  Future<List<GroupSuggestion>> getGroupingSuggestions({
    required List<TripRequest> knownRequests,
  }) {
    return _guardValue(() async {
      final dtos = await dataSource.groupingSuggestions();
      final requestsById = {
        for (final request in knownRequests) request.id: request,
      };
      return [
        for (final dto in dtos)
          ?TripRequestDtoMapper.toGroupSuggestion(
            dto: dto,
            requestsById: requestsById,
          ),
      ];
    });
  }

  void dispose() {
    for (final stream in _listPolling) {
      stream.dispose();
    }
    for (final stream in _detailPolling) {
      stream.dispose();
    }
    _listPolling.clear();
    _detailPolling.clear();
  }

  Stream<List<TripRequest>> _watchList(
    Future<List<TripRequest>> Function() fetch,
  ) {
    final polling = PollingStream<List<TripRequest>>(
      fetch: fetch,
      interval: PollingIntervals.tripRequestLists,
    );
    _listPolling.add(polling);
    return polling.stream.handleError((Object error, StackTrace stackTrace) {
      Error.throwWithStackTrace(_toFailure(error), stackTrace);
    });
  }

  Future<TripRequest?> _loadRequest(String id) async {
    try {
      final dto = await dataSource.getById(id);
      return TripRequestDtoMapper.toEntity(dto);
    } on NotFoundApiException {
      return null;
    }
  }

  List<TripRequest> _toRequests(List<TripRequestDto> dtos) {
    return [for (final dto in dtos) TripRequestDtoMapper.toEntity(dto)];
  }

  static String? _nonEmpty(String value) => value.isEmpty ? null : value;

  static int _newestFirst(TripRequest a, TripRequest b) =>
      b.createdAt.compareTo(a.createdAt);

  static int _earliestRequestedFirst(TripRequest a, TripRequest b) =>
      a.requestedDateTime.compareTo(b.requestedDateTime);

  Failure _toFailure(Object error) => failureMapper.map(error);

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(_toFailure(error), stackTrace);
    }
  }

  Future<T> _guardValue<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(_toFailure(error), stackTrace);
    }
  }
}
