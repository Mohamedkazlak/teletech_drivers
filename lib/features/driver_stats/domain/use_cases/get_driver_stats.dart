import 'package:teletech_drivers/features/driver_stats/domain/entities/driver_stats.dart';
import 'package:teletech_drivers/features/driver_stats/domain/entities/driver_stats_query.dart';
import 'package:teletech_drivers/features/driver_stats/domain/repositories/driver_stats_repository.dart';

class GetDriverStatsUseCase {
  const GetDriverStatsUseCase(this._repository);

  final DriverStatsRepository _repository;

  Future<DriverStats> call(DriverStatsQuery query) {
    return _repository.getMine(query);
  }

  Future<DriverStats> forDriver(String driverId, DriverStatsQuery query) {
    return _repository.getForDriver(driverId, query);
  }
}
