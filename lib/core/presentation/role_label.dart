import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/features/auth/domain/entities/user_role.dart';

String roleLabel(UserRole role, AppLocalizations l10n) {
  return switch (role) {
    UserRole.admin => l10n.roleLabelAdmin,
    UserRole.employee => l10n.roleLabelEmployee,
    UserRole.driver => l10n.roleLabelDriver,
    UserRole.companyAdmin => l10n.roleLabelCompanyAdmin,
    UserRole.driversAdmin => l10n.roleLabelDriversAdmin,
  };
}
