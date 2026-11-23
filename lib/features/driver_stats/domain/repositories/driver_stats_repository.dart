import 'package:teletech_drivers/features/driver_stats/domain/entities/driver_stats.dart';
import 'package:teletech_drivers/features/driver_stats/domain/entities/driver_stats_query.dart';

/// Repository: the signed-in driver's stats.
abstract interface class DriverStatsRepository {
  Future<DriverStats> getMine(DriverStatsQuery query);

  Future<DriverStats> getForDriver(String driverId, DriverStatsQuery query);
}
