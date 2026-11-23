import 'package:teletech_drivers/core/network/api_failure_mapper.dart';
import 'package:teletech_drivers/features/driver_stats/data/datasources/driver_stats_remote_data_source.dart';
import 'package:teletech_drivers/features/driver_stats/data/mappers/driver_stats_dto_mapper.dart';
import 'package:teletech_drivers/features/driver_stats/domain/entities/driver_stats.dart';
import 'package:teletech_drivers/features/driver_stats/domain/entities/driver_stats_query.dart';
import 'package:teletech_drivers/features/driver_stats/domain/repositories/driver_stats_repository.dart';

/// Repository: Laravel `GET /auth/me/stats`.
class ApiDriverStatsRepository implements DriverStatsRepository {
  ApiDriverStatsRepository({
    required this.dataSource,
    this.failureMapper = const ApiFailureMapper(),
  });

  final DriverStatsRemoteDataSource dataSource;
  final ApiFailureMapper failureMapper;

  @override
  Future<DriverStats> getMine(DriverStatsQuery query) async {
    try {
      final dto = await dataSource.getMine(period: query.period, date: query.date);
      return DriverStatsDtoMapper.toEntity(dto);
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(failureMapper.map(error), stackTrace);
    }
  }

  @override
  Future<DriverStats> getForDriver(
    String driverId,
    DriverStatsQuery query,
  ) async {
    try {
      final dto = await dataSource.getForDriver(
        driverId,
        period: query.period,
        date: query.date,
      );
      return DriverStatsDtoMapper.toEntity(dto);
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(failureMapper.map(error), stackTrace);
    }
  }
}
