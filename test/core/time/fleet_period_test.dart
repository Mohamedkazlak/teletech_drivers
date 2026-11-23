import 'package:flutter_test/flutter_test.dart';
import 'package:teletech_drivers/core/time/fleet_period.dart';

void main() {
  test('week starts on Saturday and ends on Friday', () {
    final sunday = DateTime(2026, 11, 8);
    final anchor = FleetPeriodAnchor(kind: FleetPeriodKind.week, day: sunday);

    expect(anchor.bounds.start, DateTime(2026, 11, 7));
    expect(anchor.bounds.endInclusive, DateTime(2026, 11, 13));
    expect(anchor.apiPeriod, 'week');
    expect(anchor.apiDate, '2026-11-08');
  });

  test('previous week and next are blocked on the current week', () {
    final today = DateTime(2026, 11, 8);
    final anchor = FleetPeriodAnchor(kind: FleetPeriodKind.week, day: today);

    expect(anchor.canGoForward(today), isFalse);
    expect(
      anchor.shift(-1).bounds.start,
      DateTime(2026, 10, 31),
    );
  });

  test('all period does not send a date and cannot shift', () {
    final anchor = FleetPeriodAnchor(
      kind: FleetPeriodKind.all,
      day: DateTime(2026, 11, 8),
    );

    expect(anchor.apiPeriod, 'all');
    expect(anchor.apiDate, isNull);
    expect(anchor.canShift, isFalse);
    expect(anchor.shift(1), anchor);
  });

  test('month shift lands on the first of the next month', () {
    final anchor = FleetPeriodAnchor(
      kind: FleetPeriodKind.month,
      day: DateTime(2026, 11, 8),
    );

    expect(anchor.shift(1).day, DateTime(2026, 12, 1));
    expect(anchor.apiDate, '2026-11-08');
  });
}
