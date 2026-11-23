import 'package:equatable/equatable.dart';

/// Base type for domain/application failures shown to the user.
sealed class Failure extends Equatable {
  const Failure();

  @override
  List<Object?> get props => const [];
}

final class NetworkFailure extends Failure {
  const NetworkFailure();
}

/// Why an [AuthFailure] happened, without exposing backend exception text.
enum AuthErrorKind {
  generic,
  invalidEmail,
  invalidCredentials,
  userDisabled,
  accountInactive,
  emailAlreadyInUse,
  weakPassword,
  tooManyRequests,
  operationNotAllowed,
  missingProfile,
  invalidProfile,
  orphanedAccountCleanupFailed,
  sessionExpired,
  passwordChangeRequired,
}

/// Authentication failed. [kind] selects the localized message.
final class AuthFailure extends Failure {
  const AuthFailure({this.kind = AuthErrorKind.generic});

  final AuthErrorKind kind;

  @override
  List<Object?> get props => [kind];
}

final class PermissionFailure extends Failure {
  const PermissionFailure();
}

/// Why a [LocationFailure] happened (GPS / permission / mock).
enum LocationErrorKind {
  servicesDisabled,
  permissionDenied,
  permanentlyDenied,
  approximateOnly,
  inaccurate,
  mocked,
  unavailable,
  timedOut,
}

/// Location could not be obtained or did not meet quality rules.
final class LocationFailure extends Failure {
  const LocationFailure([this.kind = LocationErrorKind.unavailable]);

  final LocationErrorKind kind;

  @override
  List<Object?> get props => [kind];
}

/// The resource was not found, or is not available to this user.
final class NotFoundFailure extends Failure {
  const NotFoundFailure();
}

/// The action is not allowed in the current lifecycle state.
final class InvalidStateFailure extends Failure {
  const InvalidStateFailure();
}

/// A create/update conflicts with an existing resource (e.g. duplicate name).
final class ConflictFailure extends Failure {
  const ConflictFailure([this.serverMessage]);

  /// Optional server `message` from a `409` response.
  final String? serverMessage;

  @override
  List<Object?> get props => [serverMessage];
}

/// Request validation failed (`422`) with optional per-field errors.
final class ValidationFailure extends Failure {
  const ValidationFailure({
    this.message,
    this.fieldErrors = const <String, List<String>>{},
  });

  final String? message;
  final Map<String, List<String>> fieldErrors;

  @override
  List<Object?> get props => [message, fieldErrors];
}

/// Unexpected server error (`5xx`).
final class ServerFailure extends Failure {
  const ServerFailure([this.message]);

  final String? message;

  @override
  List<Object?> get props => [message];
}

/// Attendance scan or adjustment rejected by the server.
final class AttendanceFailure extends Failure {
  const AttendanceFailure({required this.code, this.distanceM, this.radiusM});

  final String code;
  final int? distanceM;
  final int? radiusM;

  @override
  List<Object?> get props => [code, distanceM, radiusM];
}

final class UnknownFailure extends Failure {
  const UnknownFailure([this.serverMessage]);

  /// Server `message` when the status was not mapped to a more specific failure.
  final String? serverMessage;

  @override
  List<Object?> get props => [serverMessage];
}
