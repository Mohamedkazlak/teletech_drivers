import 'package:flutter_test/flutter_test.dart';
import 'package:teletech_drivers/core/errors/failures.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations_en.dart';
import 'package:teletech_drivers/core/utils/failure_messages.dart';

void main() {
  final l10n = AppLocalizationsEn();

  test('a 422 shows the API message and the field error', () {
    const Failure failure = ValidationFailure(
      message: 'The given data was invalid.',
      fieldErrors: {
        'return_route': ['The return route field is required.'],
      },
    );

    expect(
      failure.message(l10n),
      'The given data was invalid.\nThe return route field is required.',
    );
  });

  test('an unmapped API error shows the server message', () {
    expect(const UnknownFailure('Forbidden.').message(l10n), 'Forbidden.');
    expect(const UnknownFailure().message(l10n), l10n.errorUnknown);
  });
}
