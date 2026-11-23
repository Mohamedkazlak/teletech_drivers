import 'package:flutter_test/flutter_test.dart';
import 'package:teletech_drivers/core/errors/failures.dart';
import 'package:teletech_drivers/features/tracking/data/services/phase_upload_retry.dart';

void main() {
  test('a validation failure is not retried', () async {
    final retry = PhaseUploadRetry();
    var calls = 0;

    await expectLater(
      retry.run(
        () async {
          calls++;
          throw const ValidationFailure(
            message: 'The given data was invalid.',
            fieldErrors: {
              'return_route': ['The return route field is required.'],
            },
          );
        },
        shouldRetry: (error) =>
            error is NetworkFailure || error is ServerFailure,
      ),
      throwsA(
        isA<ValidationFailure>().having(
          (failure) => failure.fieldErrors['return_route'],
          'return_route',
          ['The return route field is required.'],
        ),
      ),
    );
    expect(calls, 1);
  });
}
