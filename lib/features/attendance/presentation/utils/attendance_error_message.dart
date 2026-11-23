import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';

/// Friendly copy for an attendance error code. Unknown codes use [fallback].
String attendanceErrorMessage(
  AppLocalizations l10n, {
  required String code,
  int? distanceM,
  int? radiusM,
  String? fallback,
}) {
  return switch (code) {
    'invalid_qr' => l10n.attendanceInvalidQr,
    'mock_location' => l10n.attendanceMockLocation,
    'low_accuracy' => l10n.attendanceLowAccuracy,
    'outside_radius' => l10n.attendanceOutsideRadius(
      distanceM ?? 0,
      radiusM ?? 0,
    ),
    'already_checked_in' => l10n.attendanceAlreadyCheckedIn,
    'not_checked_in' => l10n.attendanceNotCheckedInError,
    'already_checked_out' => l10n.attendanceAlreadyCheckedOut,
    'active_trip' => l10n.attendanceActiveTrip,
    _ =>
      (fallback != null && fallback.trim().isNotEmpty)
          ? fallback.trim()
          : l10n.errorUnknown,
  };
}
