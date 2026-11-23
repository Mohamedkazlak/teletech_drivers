import 'package:teletech_drivers/core/constants/api_json_keys.dart';
import 'package:teletech_drivers/core/constants/api_paths.dart';
import 'package:teletech_drivers/core/network/api_client.dart';
import 'package:teletech_drivers/core/network/api_json_parsers.dart';
import 'package:teletech_drivers/features/trip/data/datasources/trip_remote_data_source.dart';
import 'package:teletech_drivers/features/trip/data/mappers/trip_status_mapper.dart';
import 'package:teletech_drivers/features/trip/data/models/driver_recommendation_dto.dart';
import 'package:teletech_drivers/features/trip/data/models/trip_dto.dart';
import 'package:teletech_drivers/core/network/paginated_response.dart';
import 'package:teletech_drivers/features/auth/domain/entities/branch.dart';
import 'package:teletech_drivers/features/trip/data/models/trip_report_dto.dart';
import 'package:teletech_drivers/features/trip/domain/entities/created_trip_bucket.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_lifecycle.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_stage.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_status.dart';

class ApiTripRemoteDataSource implements TripRemoteDataSource {
  const ApiTripRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<List<TripDto>> listTrips({
    TripStatus? status,
    String? driverId,
    TripStage? stage,
    Branch? branch,
    TripLifecycle? lifecycle,
  }) {
    return apiClient.fetchAllPages(
      path: ApiPaths.trips,
      query: {
        ApiJsonKeys.status: ?_statusQuery(status),
        ApiJsonKeys.driverId: ?driverId,
        ApiJsonKeys.stage: ?stage?.apiValue,
        ApiJsonKeys.branch: ?branch?.wireValue,
        ApiJsonKeys.lifecycle: ?lifecycle?.apiValue,
      },
      mapItem: TripDto.fromJson,
    );
  }

  @override
  Future<PaginatedResponse<TripDto>> listCreatedByMe({
    required CreatedTripBucket bucket,
    required int page,
  }) async {
    final response = await apiClient.get(
      ApiPaths.myTrips,
      queryParameters: {
        ApiJsonKeys.bucket: bucket.name,
        ApiJsonKeys.page: page,
        ApiJsonKeys.perPage: 15,
      },
    );
    return PaginatedResponse.fromJson(
      ApiJsonParsers.requireMap(response.data),
      TripDto.fromJson,
    );
  }

  @override
  Future<List<TripDto>> listMyTrips({
    TripStatus? status,
    String? statusFilter,
    String? period,
    String? date,
  }) {
    final statusQuery = (statusFilter != null && statusFilter.isNotEmpty)
        ? statusFilter
        : _statusQuery(status);
    return apiClient.fetchAllPages(
      path: ApiPaths.tripsMine,
      query: {
        ApiJsonKeys.status: ?statusQuery,
        ApiJsonKeys.period: ?period,
        ApiJsonKeys.date: ?date,
      },
      mapItem: TripDto.fromJson,
    );
  }

  @override
  Future<TripDto> getTrip(String tripId) async {
    final response = await apiClient.get(ApiPaths.trip(tripId));
    return _toTrip(response.data);
  }

  @override
  Future<List<TripDto>> createFromRequests({
    required String mode,
    required List<String> requestIds,
    DateTime? scheduledAt,
  }) async {
    final response = await apiClient.post(
      ApiPaths.tripsFromRequests,
      data: {
        ApiJsonKeys.mode: mode,
        ApiJsonKeys.requestIds: requestIds,
        if (scheduledAt != null)
          ApiJsonKeys.scheduledAt: scheduledAt.toUtc().toIso8601String(),
      },
    );
    return _toList(response.data, TripDto.fromJson);
  }

  @override
  Future<TripDto> assign({
    required String tripId,
    required String driverId,
  }) async {
    final response = await apiClient.post(
      ApiPaths.tripAssign(tripId),
      data: {ApiJsonKeys.driverId: driverId},
    );
    return _toTrip(response.data);
  }

  @override
  Future<TripDto> cancel(String tripId) async {
    final response = await apiClient.post(ApiPaths.tripCancel(tripId));
    return _toTrip(response.data);
  }

  @override
  Future<TripDto> start({
    required String tripId,
    required double startLat,
    required double startLng,
  }) async {
    final response = await apiClient.post(
      ApiPaths.tripStart(tripId),
      data: {ApiJsonKeys.startLat: startLat, ApiJsonKeys.startLng: startLng},
    );
    return _toTrip(response.data);
  }

  @override
  Future<TripDto> arrive({
    required String tripId,
    required double goingDistanceM,
    required String goingRoute,
  }) async {
    final response = await apiClient.post(
      ApiPaths.tripArrive(tripId),
      data: {
        ApiJsonKeys.goingDistanceM: goingDistanceM,
        ApiJsonKeys.goingRoute: goingRoute,
      },
    );
    return _toTrip(response.data);
  }

  @override
  Future<TripDto> startReturn(String tripId) async {
    final response = await apiClient.post(ApiPaths.tripStartReturn(tripId));
    return _toTrip(response.data);
  }

  @override
  Future<TripDto> end({
    required String tripId,
    required double returnDistanceM,
    required String returnRoute,
  }) async {
    final response = await apiClient.post(
      ApiPaths.tripEnd(tripId),
      data: {
        ApiJsonKeys.returnDistanceM: returnDistanceM,
        ApiJsonKeys.returnRoute: returnRoute,
      },
    );
    return _toTrip(response.data);
  }

  @override
  Future<TripReportDto> getReport(String tripId) async {
    final response = await apiClient.get(ApiPaths.tripReport(tripId));
    return TripReportDto.fromJson(ApiJsonParsers.requireMap(response.data));
  }

  @override
  Future<List<DriverRecommendationDto>> getDriverRecommendations(
    String tripId,
  ) async {
    final response = await apiClient.get(
      ApiPaths.tripDriverRecommendations(tripId),
    );
    return _toList(response.data, DriverRecommendationDto.fromJson);
  }

  static String? _statusQuery(TripStatus? status) {
    if (status == null) return null;
    return TripStatusMapper.toApi(status);
  }

  static TripDto _toTrip(Object? data) {
    return TripDto.fromJson(ApiJsonParsers.requireMap(data));
  }

  static List<T> _toList<T>(
    Object? data,
    T Function(Map<String, dynamic> json) mapItem,
  ) {
    final body = ApiJsonParsers.requireMap(data);
    return [
      for (final item in ApiJsonParsers.objectList(
        body[ApiJsonKeys.data],
        ApiJsonKeys.data,
      ))
        mapItem(item),
    ];
  }
}
