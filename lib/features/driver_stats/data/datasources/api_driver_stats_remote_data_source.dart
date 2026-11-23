import 'package:teletech_drivers/core/constants/api_json_keys.dart';
import 'package:teletech_drivers/core/constants/api_paths.dart';
import 'package:teletech_drivers/core/network/api_client.dart';
import 'package:teletech_drivers/core/network/api_json_parsers.dart';
import 'package:teletech_drivers/features/driver_stats/data/datasources/driver_stats_remote_data_source.dart';
import 'package:teletech_drivers/features/driver_stats/data/models/driver_stats_dto.dart';

class ApiDriverStatsRemoteDataSource implements DriverStatsRemoteDataSource {
  const ApiDriverStatsRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<DriverStatsDto> getMine({required String period, String? date}) async {
    final response = await apiClient.get(
      ApiPaths.authMeStats,
      queryParameters: {
        ApiJsonKeys.period: period,
        ApiJsonKeys.date: ?date,
      },
    );
    return DriverStatsDto.fromJson(ApiJsonParsers.requireMap(response.data));
  }

  @override
  Future<DriverStatsDto> getForDriver(
    String driverId, {
    required String period,
    String? date,
  }) async {
    final response = await apiClient.get(
      ApiPaths.driverStats(driverId),
      queryParameters: {
        ApiJsonKeys.period: period,
        ApiJsonKeys.date: ?date,
      },
    );
    return DriverStatsDto.fromJson(ApiJsonParsers.requireMap(response.data));
  }
}
