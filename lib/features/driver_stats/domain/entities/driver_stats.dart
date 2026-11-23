import 'package:equatable/equatable.dart';
import 'package:teletech_drivers/features/driver_stats/domain/entities/stats_bucket.dart';

/// Driver totals from `GET /auth/me/stats`.
class DriverStats extends Equatable {
  const DriverStats({
    required this.period,
    required this.trips,
    required this.totalSeconds,
    required this.totalKm,
    required this.breakdown,
    this.from,
    this.to,
  });

  final String period;
  final DateTime? from;
  final DateTime? to;
  final int trips;
  final int totalSeconds;
  final double totalKm;
  final List<StatsBucket> breakdown;

  @override
  List<Object?> get props => [
    period,
    from,
    to,
    trips,
    totalSeconds,
    totalKm,
    breakdown,
  ];
}
