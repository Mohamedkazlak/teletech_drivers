import 'package:teletech_drivers/core/errors/failures.dart';
import 'package:teletech_drivers/core/network/api_exception.dart';

/// Maps [ApiException] (and already-mapped [Failure]s) onto domain failures.
final class ApiFailureMapper {
  const ApiFailureMapper();

  Failure map(Object error) {
    if (error is Failure) return error;
    if (error is UnauthorizedApiException) {
      return const AuthFailure(kind: AuthErrorKind.sessionExpired);
    }
    if (error is ForbiddenApiException) {
      if (error.isPasswordChangeRequired) {
        return const AuthFailure(kind: AuthErrorKind.passwordChangeRequired);
      }
      return const PermissionFailure();
    }
    if (error is NotFoundApiException) {
      return const NotFoundFailure();
    }
    if (error is ConflictApiException) {
      return ConflictFailure(error.message);
    }
    if (error is ValidationApiException) {
      return ValidationFailure(
        message: error.message,
        fieldErrors: error.fieldErrors,
      );
    }
    if (error is NetworkApiException) {
      return const NetworkFailure();
    }
    if (error is ServerApiException) {
      return ServerFailure(error.message);
    }
    if (error is TooManyRequestsApiException) {
      return UnknownFailure(error.message);
    }
    if (error is UnexpectedApiException) {
      return UnknownFailure(error.message);
    }
    if (error is FormatException) {
      return const UnknownFailure();
    }
    return const UnknownFailure();
  }
}
