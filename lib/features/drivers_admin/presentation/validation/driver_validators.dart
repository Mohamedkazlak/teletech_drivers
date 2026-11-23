import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/features/auth/presentation/validation/auth_validators.dart';
import 'package:teletech_drivers/features/drivers_admin/domain/egyptian_car_plate.dart';

/// Form rules for creating and editing a driver account.
abstract final class DriverValidators {
  static const egyptNationalIdLength = 14;

  static final RegExp _digitsOnly = RegExp(r'^\d+$');
  static final RegExp _phonePattern = RegExp(r'^\+?[0-9\s-]{8,20}$');

  static String? nameEn(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) {
      return l10n.validationDriverNameEnRequired;
    }
    return null;
  }

  static String? nameAr(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) {
      return l10n.validationDriverNameArRequired;
    }
    return null;
  }

  static String? email(String? value, AppLocalizations l10n) {
    return AuthValidators.email(value, l10n);
  }

  static String? phone(String? value, AppLocalizations l10n) {
    final phone = value?.trim() ?? '';
    if (phone.isEmpty) return l10n.validationPhoneRequired;
    if (phone.length > 30) return l10n.validationPhoneTooLong;
    if (!_phonePattern.hasMatch(phone)) {
      return l10n.validationPhoneInvalid;
    }
    return null;
  }

  static String? nationalId(String? value, AppLocalizations l10n) {
    final id = value?.trim() ?? '';
    if (id.isEmpty) return l10n.validationNationalIdRequired;
    if (!_digitsOnly.hasMatch(id) || id.length != egyptNationalIdLength) {
      return l10n.validationNationalIdInvalid;
    }
    return null;
  }

  static String? carPlate({
    required String? letters,
    required String? numbers,
    required AppLocalizations l10n,
  }) {
    if (EgyptianCarPlate.fromParts(letters ?? '', numbers ?? '') == null) {
      return l10n.validationCarPlateInvalid;
    }
    return null;
  }

  static String? personalLicense(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) {
      return l10n.validationPersonalLicenseRequired;
    }
    return null;
  }
}
