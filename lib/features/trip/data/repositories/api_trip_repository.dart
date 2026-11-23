import 'package:teletech_drivers/core/constants/api_json_keys.dart';
import 'package:teletech_drivers/core/constants/polling_intervals.dart';
import 'package:teletech_drivers/core/errors/failures.dart';
import 'package:teletech_drivers/core/network/api_exception.dart';
import 'package:teletech_drivers/core/network/api_failure_mapper.dart';
import 'package:teletech_drivers/core/polling/polling_stream.dart';
import 'package:teletech_drivers/features/drivers_admin/domain/entities/driver_recommendation.dart';
import 'package:teletech_drivers/features/trip/data/datasources/trip_remote_data_source.dart';
import 'package:teletech_drivers/features/trip/data/mappers/trip_dto_mapper.dart';
import 'package:teletech_drivers/features/trip/data/models/trip_dto.dart';
import 'package:teletech_drivers/features/trip/domain/entities/created_trip_bucket.dart';
import 'package:teletech_drivers/features/trip/domain/entities/mine_trips_filter.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_list_query.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_page.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_phase_payload.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_report.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_status.dart';
import 'package:teletech_drivers/features/trip/domain/repositories/trip_repository.dart';
import 'package:teletech_drivers/features/trip/domain/strategies/grouped_requests.dart';
import 'package:teletech_drivers/features/trip/domain/strategies/trip_grouping_strategy.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request.dart';

/// Repository: Laravel trips API with polling streams.
class ApiTripRepository implements TripRepository {
  ApiTripRepository({
    required this.dataSource,
    this.failureMapper = const ApiFailureMapper(),
  });

  final TripRemoteDataSource dataSource;
  final ApiFailureMapper failureMapper;

  final _listPolling = <PollingStream<List<Trip>>>[];
  final _detailPolling = <PollingStream<Trip?>>[];

  @override
  Future<List<Trip>> createTripsFromRequests({
    required List<TripRequest> requests,
    required TripGroupingStrategy strategy,
    required String createdBy,
    DateTime? scheduledAt,
  }) {
    return _guardValue(() async {
      if (requests.isEmpty) {
        throw const InvalidStateFailure();
      }
      final created = await dataSource.createFromRequests(
        mode: strategy is GroupedRequests
            ? ApiJsonKeys.modeGrouped
            : ApiJsonKeys.modeOnePerRequest,
        requestIds: [for (final request in requests) request.id],
        scheduledAt: scheduledAt,
      );
      return _toTrips(created);
    });
  }

  @override
  Stream<List<Trip>> watchAllTrips() {
    return watchTrips(const TripListQuery());
  }

  @override
  Stream<List<Trip>> watchTrips(TripListQuery query) {
    return _watchList(() async {
      final trips = _toTrips(
        await dataSource.listTrips(
          stage: query.stage,
          branch: query.branch,
          lifecycle: query.lifecycle,
        ),
      );
      return trips..sort(_newestFirst);
    });
  }

  @override
  Future<TripPage> listCreatedByMe({
    required CreatedTripBucket bucket,
    required int page,
  }) {
    return _guardValue(() async {
      final response = await dataSource.listCreatedByMe(
        bucket: bucket,
        page: page,
      );
      return TripPage(
        trips: _toTrips(response.data),
        currentPage: response.currentPage,
        lastPage: response.lastPage,
      );
    });
  }

  @override
  Stream<List<Trip>> watchTripsByStatus(TripStatus status) {
    return _watchList(() async {
      final trips = _toTrips(await dataSource.listTrips(status: status));
      return trips..sort(_newestFirst);
    });
  }

  @override
  Stream<List<Trip>> watchMyTrips(MineTripsFilter filter) {
    return _watchList(() async {
      final trips = _toTrips(
        await dataSource.listMyTrips(
          statusFilter: filter.status,
          period: filter.period,
          date: filter.date,
        ),
      );
      if (filter.status == MineTripStatuses.completed) {
        trips.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
      } else {
        trips.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      }
      return trips;
    });
  }

  @override
  Stream<List<Trip>> watchTripsByDriver(String driverId) {
    // Drivers may only call `/trips/mine`; admin screens that need another
    // driver's trips use filtered `watchAllTrips` / list filters instead.
    return _watchList(() async {
      final trips = _toTrips(await dataSource.listMyTrips());
      final filtered = [
        for (final trip in trips)
          if (trip.driverId == driverId) trip,
      ]..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      return filtered;
    });
  }

  @override
  Future<Trip?> getTripById(String tripId) {
    return _guardValue(() => _loadTrip(tripId));
  }

  @override
  Stream<Trip?> watchTripById(String tripId) {
    final polling = PollingStream<Trip?>(
      fetch: () => _loadTrip(tripId),
      interval: PollingIntervals.tripDetails,
    );
    _detailPolling.add(polling);
    return polling.stream.handleError((Object error, StackTrace stackTrace) {
      Error.throwWithStackTrace(_toFailure(error), stackTrace);
    });
  }

  @override
  Future<void> assignDriver({
    required String tripId,
    required String driverId,
  }) {
    return _guard(() => dataSource.assign(tripId: tripId, driverId: driverId));
  }

  @override
  Future<void> reassignDriver({
    required String tripId,
    required String driverId,
  }) {
    return assignDriver(tripId: tripId, driverId: driverId);
  }

  @override
  Future<void> cancelTrip(String tripId) {
    return _guard(() => dataSource.cancel(tripId));
  }

  @override
  Future<void> startTrip({
    required String tripId,
    required StartTripPayload payload,
  }) {
    return _guard(
      () => dataSource.start(
        tripId: tripId,
        startLat: payload.startLat,
        startLng: payload.startLng,
      ),
    );
  }

  @override
  Future<void> arriveAtDestination({
    required String tripId,
    required ArriveDestinationPayload payload,
  }) {
    return _guard(
      () => dataSource.arrive(
        tripId: tripId,
        goingDistanceM: payload.goingDistanceMeters,
        goingRoute: payload.goingRoute,
      ),
    );
  }

  @override
  Future<void> startReturn(String tripId) {
    return _guard(() => dataSource.startReturn(tripId));
  }

  @override
  Future<void> endTrip({
    required String tripId,
    required EndTripPayload payload,
  }) {
    return _guard(
      () => dataSource.end(
        tripId: tripId,
        returnDistanceM: payload.returnDistanceMeters,
        returnRoute: payload.returnRoute,
      ),
    );
  }

  @override
  Future<TripReport> getTripReport(String tripId) {
    return _guardValue(() async {
      final dto = await dataSource.getReport(tripId);
      return TripDtoMapper.toReport(dto);
    });
  }

  @override
  Future<List<DriverRecommendation>> getDriverRecommendations(String tripId) {
    return _guardValue(() async {
      final dtos = await dataSource.getDriverRecommendations(tripId);
      return [for (final dto in dtos) TripDtoMapper.toRecommendation(dto)];
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

  Stream<List<Trip>> _watchList(Future<List<Trip>> Function() fetch) {
    final polling = PollingStream<List<Trip>>(
      fetch: fetch,
      interval: PollingIntervals.tripLists,
    );
    _listPolling.add(polling);
    return polling.stream.handleError((Object error, StackTrace stackTrace) {
      Error.throwWithStackTrace(_toFailure(error), stackTrace);
    });
  }

  Future<Trip?> _loadTrip(String tripId) async {
    try {
      final dto = await dataSource.getTrip(tripId);
      return TripDtoMapper.toEntity(dto);
    } on NotFoundApiException {
      return null;
    }
  }

  List<Trip> _toTrips(List<TripDto> dtos) {
    return [for (final dto in dtos) TripDtoMapper.toEntity(dto)];
  }

  static int _newestFirst(Trip a, Trip b) => b.createdAt.compareTo(a.createdAt);

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
