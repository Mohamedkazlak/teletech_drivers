import 'package:equatable/equatable.dart';

/// Query for `GET /trips/mine` (`status`, `period`, `date`).
class MineTripsFilter extends Equatable {
  const MineTripsFilter({
    required this.status,
    required this.period,
    required this.date,
  });

  /// `all_assigned`, `completed`, or a single trip status.
  final String status;

  /// `week`, `month`, or `year`.
  final String period;

  /// `yyyy-MM-dd` anchor inside the period.
  final String date;

  @override
  List<Object?> get props => [status, period, date];
}

/// Status values the driver screens send to `/trips/mine`.
abstract final class MineTripStatuses {
  static const allAssigned = 'all_assigned';
  static const completed = 'completed';
}
