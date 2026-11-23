import 'package:teletech_drivers/core/time/cairo_clock.dart';

/// Which calendar days and clock minutes may be scheduled.
///
/// A minute is selectable only when that minute (second 0) is strictly after
/// "now" in Africa/Cairo. Exactly now is closed, matching the API.
final class FutureSchedule {
  const FutureSchedule({DateTime Function()? now}) : _now = now ?? CairoClock.now;

  final DateTime Function() _now;

  /// Current Africa/Cairo wall clock.
  DateTime get cairoNow => _now();

  /// The first minute that is still in the future.
  DateTime nextSlot() {
    final now = cairoNow;
    final truncated = DateTime(now.year, now.month, now.day, now.hour, now.minute);
    return truncated.add(const Duration(minutes: 1));
  }

  /// First calendar day that still has a future minute. Past days are closed.
  DateTime earliestDay() {
    final slot = nextSlot();
    return DateTime(slot.year, slot.month, slot.day);
  }

  bool isDaySelectable(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    return !date.isBefore(earliestDay());
  }

  bool isMinuteSelectable(DateTime day, int hour, int minute) {
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return false;
    if (!isDaySelectable(day)) return false;
    final slot = DateTime(day.year, day.month, day.day, hour, minute);
    return slot.isAfter(cairoNow);
  }

  bool hourHasSelectableMinute(DateTime day, int hour) {
    for (var minute = 0; minute < 60; minute++) {
      if (isMinuteSelectable(day, hour, minute)) return true;
    }
    return false;
  }
}
