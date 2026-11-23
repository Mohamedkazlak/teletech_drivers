import 'package:teletech_drivers/features/driver_stats/data/models/driver_stats_dto.dart';
import 'package:teletech_drivers/features/driver_stats/domain/entities/driver_stats.dart';
import 'package:teletech_drivers/features/driver_stats/domain/entities/stats_bucket.dart';

abstract final class DriverStatsDtoMapper {
  static DriverStats toEntity(DriverStatsDto dto) {
    return DriverStats(
      period: dto.period,
      from: dto.from,
      to: dto.to,
      trips: dto.trips,
      totalSeconds: dto.totalSeconds,
      totalKm: dto.totalKm,
      breakdown: [
        for (final bucket in dto.breakdown)
          StatsBucket(
            label: bucket.label,
            from: bucket.from,
            to: bucket.to,
            trips: bucket.trips,
            totalSeconds: bucket.totalSeconds,
            totalKm: bucket.totalKm,
          ),
      ],
    );
  }
}
