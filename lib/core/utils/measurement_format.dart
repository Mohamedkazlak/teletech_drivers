/// `h:mm` from a whole number of seconds. Negative values become `0:00`.
String formatHoursMinutes(int totalSeconds) {
  final seconds = totalSeconds < 0 ? 0 : totalSeconds;
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  return '$hours:${minutes.toString().padLeft(2, '0')}';
}

/// Hours and minutes between [start] and [end], or null when either is missing.
String? formatSpanHoursMinutes(DateTime? start, DateTime? end) {
  if (start == null || end == null) return null;
  final seconds = end.difference(start).inSeconds;
  if (seconds < 0) return null;
  return formatHoursMinutes(seconds);
}

/// Kilometres without a trailing `.0`. Null when [kilometers] is null.
String formatKilometers(double kilometers) {
  if (kilometers == kilometers.roundToDouble()) {
    return kilometers.toStringAsFixed(0);
  }
  return kilometers.toStringAsFixed(1);
}

/// Converts meters to a kilometre label. Null when [meters] is null.
String? formatKilometersFromMeters(double? meters) {
  if (meters == null) return null;
  return formatKilometers(meters / 1000);
}
