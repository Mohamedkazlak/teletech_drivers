import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/features/auth/presentation/validation/auth_validators.dart';

void main() {
  late AppLocalizations en;
  late AppLocalizations ar;

  setUpAll(() async {
    en = await AppLocalizations.delegate.load(const Locale('en'));
    ar = await AppLocalizations.delegate.load(const Locale('ar'));
  });

  group('AuthValidators.phone', () {
    test('requires a phone and uses the too-long message past 30 characters', () {
      expect(AuthValidators.phone(null, en), en.validationPhoneRequired);
      expect(AuthValidators.phone('  ', en), en.validationPhoneRequired);
      expect(AuthValidators.phone('01011111111', en), isNull);
      expect(AuthValidators.phone('1' * 31, en), en.validationPhoneTooLong);
      expect(en.validationPhoneTooLong, isNot(en.validationPhoneRequired));
    });
  });

  group('AuthValidators.password', () {
    test('requires a password', () {
      expect(AuthValidators.password(null, en), en.validationPasswordRequired);
      expect(AuthValidators.password('', en), en.validationPasswordRequired);
    });

    test('matches Password::defaults minimum of 8 and no other rules', () {
      expect(AuthValidators.minPasswordLength, 8);
      expect(
        AuthValidators.password('1234567', en),
        en.validationPasswordShort,
      );
      expect(AuthValidators.password('12345678', en), isNull);
      expect(AuthValidators.password('password', en), isNull);
    });

    test('length messages name 8 characters in English and Arabic', () {
      expect(en.validationPasswordShort, 'Use at least 8 characters.');
      expect(ar.validationPasswordShort, 'استخدم 8 أحرف على الأقل.');
      expect(
        en.errorWeakPassword,
        'The password is too weak. Use at least 8 characters.',
      );
      expect(
        ar.errorWeakPassword,
        'كلمة المرور ضعيفة. استخدم 8 أحرف على الأقل.',
      );
    });
  });
}
