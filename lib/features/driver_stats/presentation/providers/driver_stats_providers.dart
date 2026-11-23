import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/presentation/fleet_period_controller.dart';
import 'package:teletech_drivers/core/time/fleet_period.dart';
import 'package:teletech_drivers/features/driver_stats/data/providers/driver_stats_repository_provider.dart';
import 'package:teletech_drivers/features/driver_stats/domain/entities/driver_stats.dart';
import 'package:teletech_drivers/features/driver_stats/domain/entities/driver_stats_query.dart';
import 'package:teletech_drivers/features/driver_stats/domain/use_cases/get_driver_stats.dart';

/// Dependency Injection: Riverpod.
final getDriverStatsUseCaseProvider = Provider<GetDriverStatsUseCase>((ref) {
  return GetDriverStatsUseCase(ref.watch(driverStatsRepositoryProvider));
});

final driverStatsPeriodProvider =
    NotifierProvider<FleetPeriodController, FleetPeriodAnchor>(
      () => FleetPeriodController(
        allowed: const [
          FleetPeriodKind.week,
          FleetPeriodKind.month,
          FleetPeriodKind.year,
          FleetPeriodKind.all,
        ],
      ),
    );

/// Period for one driver's profile. A new driver id starts on Week.
final adminDriverPeriodProvider = NotifierProvider.autoDispose
    .family<FleetPeriodController, FleetPeriodAnchor, String>(
      (_) => FleetPeriodController(
        allowed: const [
          FleetPeriodKind.week,
          FleetPeriodKind.month,
          FleetPeriodKind.year,
          FleetPeriodKind.all,
        ],
      ),
    );

final adminDriverStatsProvider = FutureProvider.autoDispose
    .family<DriverStats, String>((ref, driverId) {
      final anchor = ref.watch(adminDriverPeriodProvider(driverId));
      return ref.watch(getDriverStatsUseCaseProvider).forDriver(
        driverId,
        DriverStatsQuery(period: anchor.apiPeriod, date: anchor.apiDate),
      );
    });

final driverStatsProvider = FutureProvider.autoDispose<DriverStats>((ref) {
  final anchor = ref.watch(driverStatsPeriodProvider);
  return ref.watch(getDriverStatsUseCaseProvider)(
    DriverStatsQuery(period: anchor.apiPeriod, date: anchor.apiDate),
  );
});
