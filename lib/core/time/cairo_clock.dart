/// Africa/Cairo wall clock. Egypt is UTC+2 year-round (no daylight saving).
abstract final class CairoClock {
  static const Duration offset = Duration(hours: 2);

  /// Cairo year, month, day, hour, and minute stored on a naive [DateTime].
  static DateTime wall(DateTime instant) {
    final shifted = instant.toUtc().add(offset);
    return DateTime(
      shifted.year,
      shifted.month,
      shifted.day,
      shifted.hour,
      shifted.minute,
      shifted.second,
      shifted.millisecond,
      shifted.microsecond,
    );
  }

  static DateTime now() => wall(DateTime.now());

  /// True when [a] and [b] fall on the same Africa/Cairo calendar day.
  static bool isSameDay(DateTime a, DateTime b) {
    final left = wall(a);
    final right = wall(b);
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  /// Time until the next 00:00 Africa/Cairo. Never zero, so a timer can arm.
  static Duration untilNextMidnight(DateTime now) {
    final wallNow = wall(now);
    final nextMidnight = DateTime(wallNow.year, wallNow.month, wallNow.day + 1);
    final remaining = toUtc(nextMidnight).difference(now.toUtc());
    if (remaining <= Duration.zero) return const Duration(seconds: 1);
    return remaining;
  }

  /// Interprets [wallClock] as Africa/Cairo and returns the UTC instant.
  static DateTime toUtc(DateTime wallClock) {
    return DateTime.utc(
      wallClock.year,
      wallClock.month,
      wallClock.day,
      wallClock.hour,
      wallClock.minute,
      wallClock.second,
      wallClock.millisecond,
      wallClock.microsecond,
    ).subtract(offset);
  }
}
