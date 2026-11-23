import 'package:intl/intl.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';

/// Formats trip-report values for the active locale (RTL-safe labels elsewhere).
abstract final class TripReportFormatters {
  static String dateTime(DateTime? value, String locale) {
    if (value == null) return '-';
    return DateFormat.yMMMd(locale).add_jm().format(value.toLocal());
  }

  static String duration(Duration? value, AppLocalizations l10n) {
    if (value == null) return '-';
    final totalSeconds = value.inSeconds;
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    if (hours > 0) {
      return l10n.tripReportDurationHoursMinutesSeconds(
        hours,
        minutes,
        seconds,
      );
    }
    if (minutes > 0) {
      return l10n.tripReportDurationMinutesSeconds(minutes, seconds);
    }
    return l10n.tripReportDurationSeconds(seconds);
  }

  static String distanceKm(double? km, AppLocalizations l10n) {
    if (km == null) return '-';
    return l10n.tripReportDistanceKmValue(km.toStringAsFixed(2));
  }
}
