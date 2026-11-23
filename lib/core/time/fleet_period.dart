import 'package:equatable/equatable.dart';

/// Calendar window sent to the API as `period` + `date`.
///
/// Weeks start on Saturday, matching the fleet calendar (Africa/Cairo).
enum FleetPeriodKind { week, month, year, all }

class FleetPeriodAnchor extends Equatable {
  const FleetPeriodAnchor({required this.kind, required this.day});

  final FleetPeriodKind kind;

  /// Local calendar day used as the API `date` anchor.
  final DateTime day;

  static DateTime dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  String get apiPeriod => switch (kind) {
    FleetPeriodKind.week => 'week',
    FleetPeriodKind.month => 'month',
    FleetPeriodKind.year => 'year',
    FleetPeriodKind.all => 'all',
  };

  /// `yyyy-MM-dd`, or null for [FleetPeriodKind.all].
  String? get apiDate {
    if (kind == FleetPeriodKind.all) return null;
    final year = day.year.toString().padLeft(4, '0');
    final month = day.month.toString().padLeft(2, '0');
    final date = day.day.toString().padLeft(2, '0');
    return '$year-$month-$date';
  }

  bool get canShift => kind != FleetPeriodKind.all;

  ({DateTime start, DateTime endInclusive}) get bounds {
    final day = dateOnly(this.day);
    return switch (kind) {
      FleetPeriodKind.week => _week(day),
      FleetPeriodKind.month => (
        start: DateTime(day.year, day.month),
        endInclusive: DateTime(day.year, day.month + 1, 0),
      ),
      FleetPeriodKind.year => (
        start: DateTime(day.year),
        endInclusive: DateTime(day.year, 12, 31),
      ),
      FleetPeriodKind.all => (start: day, endInclusive: day),
    };
  }

  FleetPeriodAnchor shift(int steps) {
    if (steps == 0 || !canShift) return this;
    final day = dateOnly(this.day);
    final moved = switch (kind) {
      FleetPeriodKind.week => day.add(Duration(days: 7 * steps)),
      FleetPeriodKind.month => DateTime(day.year, day.month + steps),
      FleetPeriodKind.year => DateTime(day.year + steps),
      FleetPeriodKind.all => day,
    };
    return FleetPeriodAnchor(kind: kind, day: dateOnly(moved));
  }

  /// False while [now] falls in this period, so the control cannot page ahead.
  bool canGoForward(DateTime now) {
    if (!canShift) return false;
    final today = FleetPeriodAnchor(kind: kind, day: dateOnly(now));
    return bounds.start.isBefore(today.bounds.start);
  }

  static ({DateTime start, DateTime endInclusive}) _week(DateTime day) {
    final sinceSaturday = (day.weekday - DateTime.saturday + 7) % 7;
    final start = day.subtract(Duration(days: sinceSaturday));
    return (start: start, endInclusive: start.add(const Duration(days: 6)));
  }

  @override
  List<Object?> get props => [kind, day.year, day.month, day.day];
}
