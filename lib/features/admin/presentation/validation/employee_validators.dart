import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/features/auth/domain/entities/branch.dart';
import 'package:teletech_drivers/features/auth/presentation/validation/auth_validators.dart';
import 'package:teletech_drivers/features/drivers_admin/presentation/validation/driver_validators.dart';

/// Form rules for creating and editing an employee account.
abstract final class EmployeeValidators {
  static String? nameEn(String? value, AppLocalizations l10n) {
    return DriverValidators.nameEn(value, l10n);
  }

  static String? nameAr(String? value, AppLocalizations l10n) {
    return DriverValidators.nameAr(value, l10n);
  }

  static String? email(String? value, AppLocalizations l10n) {
    return AuthValidators.email(value, l10n);
  }

  static String? phone(String? value, AppLocalizations l10n) {
    return DriverValidators.phone(value, l10n);
  }

  static String? branch(Branch? value, AppLocalizations l10n) {
    if (value == null) return l10n.validationBranchRequired;
    return null;
  }
}
