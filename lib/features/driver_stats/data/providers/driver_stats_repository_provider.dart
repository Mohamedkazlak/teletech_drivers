import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/network/network_providers.dart';
import 'package:teletech_drivers/features/driver_stats/data/datasources/api_driver_stats_remote_data_source.dart';
import 'package:teletech_drivers/features/driver_stats/data/repositories/api_driver_stats_repository.dart';
import 'package:teletech_drivers/features/driver_stats/domain/repositories/driver_stats_repository.dart';

/// Dependency Injection: Riverpod.
final driverStatsRepositoryProvider = Provider<DriverStatsRepository>((ref) {
  return ApiDriverStatsRepository(
    dataSource: ApiDriverStatsRemoteDataSource(
      apiClient: ref.watch(apiClientProvider),
    ),
  );
});
