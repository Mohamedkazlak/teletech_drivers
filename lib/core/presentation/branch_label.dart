import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/features/auth/domain/entities/branch.dart';

/// Localized display name for a [Branch].
String branchLabel(Branch branch, AppLocalizations l10n) {
  return switch (branch) {
    Branch.companyHeadquarters => l10n.branchCompanyHeadquarters,
    Branch.newHeadquarters => l10n.branchNewHeadquarters,
  };
}
