import 'package:teletech_drivers/core/constants/api_json_keys.dart';
import 'package:teletech_drivers/core/constants/api_paths.dart';
import 'package:teletech_drivers/core/network/api_client.dart';
import 'package:teletech_drivers/features/auth/data/models/user_dto.dart';
import 'package:teletech_drivers/features/drivers_admin/data/datasources/driver_remote_data_source.dart';
import 'package:teletech_drivers/features/drivers_admin/data/models/driver_completed_trip_dto.dart';

class ApiDriverRemoteDataSource implements DriverRemoteDataSource {
  const ApiDriverRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<List<UserDto>> listDrivers({
    bool includeDeleted = false,
    String? attendance,
  }) {
    return apiClient.fetchAllPages(
      path: ApiPaths.drivers,
      query: {
        if (includeDeleted) ApiJsonKeys.includeDeleted: true,
        ApiJsonKeys.attendance: ?attendance,
      },
      mapItem: UserDto.fromJson,
    );
  }

  @override
  Future<List<DriverCompletedTripDto>> listDriverTrips(
    String driverId, {
    String? period,
    String? date,
  }) {
    return apiClient.fetchAllPages(
      path: ApiPaths.driverTrips(driverId),
      query: {ApiJsonKeys.period: ?period, ApiJsonKeys.date: ?date},
      mapItem: DriverCompletedTripDto.fromJson,
    );
  }

  @override
  Future<UserDto> getDriver(String driverId) async {
    final response = await apiClient.get(ApiPaths.driver(driverId));
    return UserDto.fromJson(_asMap(response.data));
  }

  @override
  Future<UserDto> createDriver(Map<String, dynamic> body) async {
    final response = await apiClient.post(ApiPaths.drivers, data: body);
    return UserDto.fromJson(_asMap(response.data));
  }

  @override
  Future<UserDto> updateDriver({
    required String driverId,
    required Map<String, dynamic> body,
  }) async {
    final response = await apiClient.patch(
      ApiPaths.driver(driverId),
      data: body,
    );
    return UserDto.fromJson(_asMap(response.data));
  }

  @override
  Future<UserDto> softDeleteDriver(String driverId) async {
    final response = await apiClient.delete(ApiPaths.driver(driverId));
    return UserDto.fromJson(_asMap(response.data));
  }

  @override
  Future<UserDto> restoreDriver(String driverId) async {
    final response = await apiClient.post(ApiPaths.driverRestore(driverId));
    return UserDto.fromJson(_asMap(response.data));
  }

  static Map<String, dynamic> _asMap(Object? data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const FormatException('Expected JSON object');
  }
}
