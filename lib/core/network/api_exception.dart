/// Typed HTTP / transport failure from [ApiClient] before domain mapping.
sealed class ApiException implements Exception {
  const ApiException({this.message});

  final String? message;
}

final class UnauthorizedApiException extends ApiException {
  const UnauthorizedApiException({super.message});
}

final class ForbiddenApiException extends ApiException {
  const ForbiddenApiException({super.message, this.code});

  static const passwordChangeRequiredCode = 'password_change_required';

  final String? code;

  bool get isPasswordChangeRequired => code == passwordChangeRequiredCode;
}

final class NotFoundApiException extends ApiException {
  const NotFoundApiException({super.message});
}

final class ConflictApiException extends ApiException {
  const ConflictApiException({
    super.message,
    this.code,
    this.distanceM,
    this.radiusM,
  });

  final String? code;
  final int? distanceM;
  final int? radiusM;
}

final class TooManyRequestsApiException extends ApiException {
  const TooManyRequestsApiException({super.message});
}

final class ValidationApiException extends ApiException {
  const ValidationApiException({
    super.message,
    this.fieldErrors = const <String, List<String>>{},
    this.code,
    this.distanceM,
    this.radiusM,
  });

  final Map<String, List<String>> fieldErrors;
  final String? code;
  final int? distanceM;
  final int? radiusM;
}

final class ServerApiException extends ApiException {
  const ServerApiException({super.message, this.statusCode});

  final int? statusCode;
}

final class NetworkApiException extends ApiException {
  const NetworkApiException({super.message});
}

final class UnexpectedApiException extends ApiException {
  const UnexpectedApiException({super.message, this.statusCode});

  final int? statusCode;
}
