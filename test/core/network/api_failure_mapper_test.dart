import 'package:flutter_test/flutter_test.dart';
import 'package:teletech_drivers/core/errors/failures.dart';
import 'package:teletech_drivers/core/network/api_exception.dart';
import 'package:teletech_drivers/core/network/api_failure_mapper.dart';

void main() {
  const mapper = ApiFailureMapper();

  test('maps API exceptions to domain failures', () {
    expect(
      mapper.map(const UnauthorizedApiException()),
      const AuthFailure(kind: AuthErrorKind.sessionExpired),
    );
    expect(
      mapper.map(const ForbiddenApiException()),
      const PermissionFailure(),
    );
    expect(mapper.map(const NotFoundApiException()), const NotFoundFailure());
    expect(
      mapper.map(const ConflictApiException(message: 'busy')),
      const ConflictFailure('busy'),
    );
    final validation = mapper.map(
      const ValidationApiException(
        message: 'bad',
        fieldErrors: {
          'email': ['taken'],
        },
      ),
    );
    expect(
      validation,
      const ValidationFailure(
        message: 'bad',
        fieldErrors: {
          'email': ['taken'],
        },
      ),
    );
    expect(
      mapper.map(const FormatException('bad json')),
      const UnknownFailure(),
    );
    expect(
      mapper.map(
        const UnexpectedApiException(message: 'nope', statusCode: 400),
      ),
      const UnknownFailure('nope'),
    );
    expect(mapper.map(const NetworkApiException()), const NetworkFailure());
    expect(
      mapper.map(const ServerApiException(message: 'down')),
      const ServerFailure('down'),
    );
  });
}
