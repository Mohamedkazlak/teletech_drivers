import 'package:equatable/equatable.dart';

/// Query for `GET /auth/me/stats`.
class DriverStatsQuery extends Equatable {
  const DriverStatsQuery({required this.period, this.date});

  /// `week`, `month`, `year`, or `all`.
  final String period;

  /// `yyyy-MM-dd`. Omitted for [period] `all`.
  final String? date;

  @override
  List<Object?> get props => [period, date];
}
