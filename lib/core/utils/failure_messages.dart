import 'package:teletech_drivers/core/errors/failures.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/features/attendance/presentation/utils/attendance_error_message.dart';

/// Maps a [Failure] to a localized user-facing message.
extension FailureMessages on Failure {
  String message(AppLocalizations l10n) {
    return switch (this) {
      NetworkFailure() => l10n.errorNetwork,
      AuthFailure(:final kind) => switch (kind) {
        AuthErrorKind.generic => l10n.errorAuth,
        AuthErrorKind.invalidEmail => l10n.errorInvalidEmail,
        AuthErrorKind.invalidCredentials => l10n.errorInvalidCredentials,
        AuthErrorKind.userDisabled => l10n.errorUserDisabled,
        AuthErrorKind.accountInactive => l10n.errorAccountInactive,
        AuthErrorKind.emailAlreadyInUse => l10n.errorEmailAlreadyInUse,
        AuthErrorKind.weakPassword => l10n.errorWeakPassword,
        AuthErrorKind.tooManyRequests => l10n.errorTooManyRequests,
        AuthErrorKind.operationNotAllowed => l10n.errorOperationNotAllowed,
        AuthErrorKind.missingProfile => l10n.errorMissingProfile,
        AuthErrorKind.invalidProfile => l10n.errorInvalidProfile,
        AuthErrorKind.orphanedAccountCleanupFailed =>
          l10n.errorOrphanedAccountCleanupFailed,
        AuthErrorKind.sessionExpired => l10n.errorAuth,
        AuthErrorKind.passwordChangeRequired =>
          l10n.forcedChangePasswordMessage,
      },
      PermissionFailure() => l10n.errorPermission,
      LocationFailure(:final kind) => switch (kind) {
        LocationErrorKind.servicesDisabled =>
          l10n.locationServicesDisabledMessage,
        LocationErrorKind.permissionDenied =>
          l10n.locationPermissionDeniedMessage,
        LocationErrorKind.permanentlyDenied =>
          l10n.locationPermissionPermanentlyDeniedMessage,
        LocationErrorKind.approximateOnly => l10n.locationPreciseRequired,
        LocationErrorKind.inaccurate => l10n.locationInaccurate,
        LocationErrorKind.mocked => l10n.locationMocked,
        LocationErrorKind.unavailable => l10n.locationUnavailable,
        LocationErrorKind.timedOut => l10n.locationFixTimedOut,
      },
      NotFoundFailure() => l10n.errorNotFound,
      InvalidStateFailure() => l10n.errorInvalidState,
      ConflictFailure(:final serverMessage) =>
        (serverMessage != null && serverMessage.trim().isNotEmpty)
            ? serverMessage
            : l10n.errorConflict,
      ValidationFailure(:final message, :final fieldErrors) =>
        _apiErrorText(message, fieldErrors) ?? l10n.errorUnknown,
      ServerFailure(:final message) =>
        (message != null && message.trim().isNotEmpty)
            ? message
            : l10n.errorUnknown,
      AttendanceFailure(:final code, :final distanceM, :final radiusM) =>
        attendanceErrorMessage(
          l10n,
          code: code,
          distanceM: distanceM,
          radiusM: radiusM,
        ),
      UnknownFailure(:final serverMessage) =>
        (serverMessage != null && serverMessage.trim().isNotEmpty)
            ? serverMessage
            : l10n.errorUnknown,
    };
  }
}

/// Maps an arbitrary thrown object to a localized failure message.
String messageForError(Object error, AppLocalizations l10n) {
  if (error is Failure) return error.message(l10n);
  return const UnknownFailure().message(l10n);
}

/// Top-level API `message` plus per-field `errors` lines, without duplicates.
///
/// Validation responses use a generic message ("The given data was invalid.")
/// and put the reason on the field. Both are shown.
String? _apiErrorText(String? message, Map<String, List<String>> fieldErrors) {
  final lines = <String>[];
  final top = message?.trim();
  if (top != null && top.isNotEmpty) lines.add(top);
  for (final errors in fieldErrors.values) {
    for (final error in errors) {
      final line = error.trim();
      if (line.isEmpty || lines.contains(line)) continue;
      lines.add(line);
    }
  }
  if (lines.isEmpty) return null;
  return lines.join('\n');
}
