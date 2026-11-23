import 'package:intl/intl.dart';

/// Chart axis text for a stats breakdown bucket.
///
/// Week labels are weekday names, month labels are day numbers, year labels
/// are month names, and all-time labels stay as years.
String statsChartLabel({
  required String period,
  required String bucketLabel,
  required String localeName,
}) {
  final day = _calendarDay(bucketLabel);
  final month = _calendarMonth(bucketLabel);
  return switch (period) {
    'week' when day != null => DateFormat.E(localeName).format(day),
    'month' when day != null => DateFormat.d(localeName).format(day),
    'year' when month != null => DateFormat.MMM(localeName).format(month),
    _ => bucketLabel,
  };
}

DateTime? _calendarDay(String label) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(label);
  if (match == null) return null;
  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  if (month < 1 || month > 12 || day < 1 || day > 31) return null;
  return DateTime(year, month, day);
}

DateTime? _calendarMonth(String label) {
  final match = RegExp(r'^(\d{4})-(\d{2})$').firstMatch(label);
  if (match == null) return null;
  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  if (month < 1 || month > 12) return null;
  return DateTime(year, month);
}
