import 'package:equatable/equatable.dart';

/// One bar in a driver stats breakdown.
class StatsBucket extends Equatable {
  const StatsBucket({
    required this.label,
    required this.trips,
    required this.totalSeconds,
    required this.totalKm,
    this.from,
    this.to,
  });

  /// API bucket key (`yyyy-MM-dd`, `yyyy-MM`, or a year).
  final String label;
  final DateTime? from;
  final DateTime? to;
  final int trips;
  final int totalSeconds;
  final double totalKm;

  @override
  List<Object?> get props => [label, from, to, trips, totalSeconds, totalKm];
}
