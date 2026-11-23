import 'package:teletech_drivers/core/constants/api_json_keys.dart';
import 'package:teletech_drivers/core/constants/api_paths.dart';
import 'package:teletech_drivers/core/network/api_client.dart';
import 'package:teletech_drivers/core/network/api_json_parsers.dart';
import 'package:teletech_drivers/features/trip_request/data/datasources/trip_request_remote_data_source.dart';
import 'package:teletech_drivers/features/trip_request/data/mappers/trip_request_status_mapper.dart';
import 'package:teletech_drivers/features/trip_request/data/models/group_suggestion_dto.dart';
import 'package:teletech_drivers/features/trip_request/data/models/trip_request_dto.dart';
import 'package:teletech_drivers/features/auth/domain/entities/branch.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request_list_bucket.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request_stage.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request_status.dart';

/// Laravel API implementation of [TripRequestRemoteDataSource].
class ApiTripRequestRemoteDataSource implements TripRequestRemoteDataSource {
  const ApiTripRequestRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  /// Laravel `boolean` rules accept `1`/`0` but not the string `"false"`.
  static const _queryTrue = 1;
  static const _queryFalse = 0;

  @override
  Future<TripRequestDto> createRequest(Map<String, dynamic> body) async {
    final response = await apiClient.post(ApiPaths.tripRequests, data: body);
    return _toRequest(response.data);
  }

  @override
  Future<List<TripRequestDto>> listMine({
    TripRequestStatus? status,
    TripRequestListBucket? bucket,
    bool awaitingConfirmation = false,
  }) {
    return apiClient.fetchAllPages(
      path: ApiPaths.tripRequestsMine,
      query: {
        ApiJsonKeys.status: ?_statusQuery(status),
        ApiJsonKeys.bucket: ?_bucketQuery(bucket),
        if (awaitingConfirmation) ApiJsonKeys.awaitingConfirmation: _queryTrue,
      },
      mapItem: TripRequestDto.fromJson,
    );
  }

  @override
  Future<TripRequestDto> confirmTrip(
    String id, {
    required bool driverShowedUp,
    String? note,
  }) async {
    final response = await apiClient.post(
      ApiPaths.tripRequestConfirm(id),
      data: {
        ApiJsonKeys.driverShowedUp: driverShowedUp,
        ApiJsonKeys.note: ?note,
      },
    );
    return _toRequest(response.data);
  }

  @override
  Future<List<TripRequestDto>> listAll({
    TripRequestStatus? status,
    bool? hasTrip,
    Branch? branch,
    TripRequestStage? stage,
  }) {
    return apiClient.fetchAllPages(
      path: ApiPaths.tripRequests,
      query: {
        ApiJsonKeys.status: ?_statusQuery(status),
        ApiJsonKeys.hasTrip: ?_boolQuery(hasTrip),
        ApiJsonKeys.branch: ?branch?.wireValue,
        ApiJsonKeys.stage: ?stage?.apiValue,
      },
      mapItem: TripRequestDto.fromJson,
    );
  }

  @override
  Future<TripRequestDto> getById(String id) async {
    final response = await apiClient.get(ApiPaths.tripRequest(id));
    return _toRequest(response.data);
  }

  @override
  Future<TripRequestDto> cancel(String id) async {
    final response = await apiClient.post(ApiPaths.tripRequestCancel(id));
    return _toRequest(response.data);
  }

  @override
  Future<TripRequestDto> approve(String id) async {
    final response = await apiClient.post(ApiPaths.tripRequestApprove(id));
    return _toRequest(response.data);
  }

  @override
  Future<TripRequestDto> reject(String id, {String? reason}) async {
    final response = await apiClient.post(
      ApiPaths.tripRequestReject(id),
      data: {ApiJsonKeys.rejectionReason: ?reason},
    );
    return _toRequest(response.data);
  }

  @override
  Future<List<TripRequestDto>> approveGroup(List<String> requestIds) async {
    final response = await apiClient.post(
      ApiPaths.tripRequestsApproveGroup,
      data: {ApiJsonKeys.requestIds: requestIds},
    );
    return _toList(response.data, TripRequestDto.fromJson);
  }

  @override
  Future<List<GroupSuggestionDto>> groupingSuggestions() async {
    final response = await apiClient.get(
      ApiPaths.tripRequestsGroupingSuggestions,
    );
    return _toList(response.data, GroupSuggestionDto.fromJson);
  }

  static String? _statusQuery(TripRequestStatus? status) {
    if (status == null) return null;
    return TripRequestStatusMapper.toApi(status);
  }

  static String? _bucketQuery(TripRequestListBucket? bucket) => bucket?.name;

  static int? _boolQuery(bool? value) {
    if (value == null) return null;
    return value ? _queryTrue : _queryFalse;
  }

  static TripRequestDto _toRequest(Object? data) {
    return TripRequestDto.fromJson(ApiJsonParsers.requireMap(data));
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
