import 'package:equatable/equatable.dart';

/// Lifetime totals on `GET /drivers/{id}` (`totals`).
class DriverTotals extends Equatable {
  const DriverTotals({
    required this.trips,
    required this.totalSeconds,
    required this.totalKm,
  });

  final int trips;
  final int totalSeconds;
  final double totalKm;

  @override
  List<Object?> get props => [trips, totalSeconds, totalKm];
}
