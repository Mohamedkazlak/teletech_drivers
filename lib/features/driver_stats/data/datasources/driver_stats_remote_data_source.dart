import 'package:teletech_drivers/features/driver_stats/data/models/driver_stats_dto.dart';

abstract interface class DriverStatsRemoteDataSource {
  Future<DriverStatsDto> getMine({required String period, String? date});

  Future<DriverStatsDto> getForDriver(
    String driverId, {
    required String period,
    String? date,
  });
}
