import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';

/// Form rules for sign-in and employee registration.
///
/// [password] is the only password policy. It matches Laravel
/// `Password::defaults()`: required, at least 8 characters, no other rules.
abstract final class AuthValidators {
  static final RegExp _emailPattern = RegExp(
    r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$',
  );

  /// `Password::defaults()` minimum. Shared by registration, change-password,
  /// and admin create forms.
  static const minPasswordLength = 8;

  static String? name(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) {
      return l10n.validationNameRequired;
    }
    return null;
  }

  static String? email(String? value, AppLocalizations l10n) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return l10n.validationEmailRequired;
    if (!_emailPattern.hasMatch(email)) return l10n.validationEmailInvalid;
    return null;
  }

  static String? password(String? value, AppLocalizations l10n) {
    final password = value ?? '';
    if (password.isEmpty) return l10n.validationPasswordRequired;
    if (password.length < minPasswordLength) {
      return l10n.validationPasswordShort;
    }
    return null;
  }

  static String? confirmPassword(
    String? value,
    String original,
    AppLocalizations l10n,
  ) {
    if (value == null || value.isEmpty) {
      return l10n.validationConfirmPasswordRequired;
    }
    if (value != original) return l10n.validationPasswordMismatch;
    return null;
  }

  static String? phone(String? value, AppLocalizations l10n) {
    final phone = value?.trim() ?? '';
    if (phone.isEmpty) return l10n.validationPhoneRequired;
    if (phone.length > 30) return l10n.validationPhoneTooLong;
    return null;
  }

  static String? branch(Object? value, AppLocalizations l10n) {
    if (value == null) return l10n.validationBranchRequired;
    return null;
  }
}
