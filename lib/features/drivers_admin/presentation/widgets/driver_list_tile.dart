import 'package:flutter/material.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/core/widgets/status_chip.dart';
import 'package:teletech_drivers/features/drivers_admin/domain/entities/driver_profile.dart';

/// One row in the drivers list with masked national ID and actions.
class DriverListTile extends StatelessWidget {
  const DriverListTile({
    required this.driver,
    required this.isToggling,
    required this.onActiveChanged,
    required this.onEdit,
    required this.onOpenDetails,
    this.onTrip = false,
    super.key,
  });

  final DriverProfile driver;
  final bool isToggling;
  final ValueChanged<bool> onActiveChanged;
  final VoidCallback onEdit;
  final VoidCallback onOpenDetails;

  /// True when the driver has an in-progress trip (going / at destination / returning).
  final bool onTrip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final languageCode = Localizations.localeOf(context).languageCode;
    final statusLabel = driver.isActive
        ? l10n.driverStatusActive
        : l10n.driverStatusInactive;
    final nationalIdLine = driver.nationalId.isEmpty
        ? l10n.nationalIdNotSet
        : l10n.nationalIdMaskedValue(driver.maskedNationalId);

    return ListTile(
      onTap: onOpenDetails,
      contentPadding: const EdgeInsetsDirectional.fromSTEB(16, 4, 8, 4),
      title: Row(
        children: [
          Expanded(
            child: Text(
              driver.localizedName(languageCode),
              style: textTheme.titleMedium,
            ),
          ),
          _availabilityChip(l10n),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(driver.email, style: textTheme.bodyMedium),
          Text(driver.phone, style: textTheme.bodySmall),
          Text(nationalIdLine, style: textTheme.bodySmall),
          Text(statusLabel, style: textTheme.bodySmall),
        ],
      ),
      isThreeLine: true,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: l10n.editDriver,
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
          if (isToggling)
            const SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Switch.adaptive(value: driver.isActive, onChanged: onActiveChanged),
        ],
      ),
    );
  }

  Widget _availabilityChip(AppLocalizations l10n) {
    if (onTrip) {
      return StatusChip(
        label: l10n.attendanceOnTrip,
        color: AppColors.deepBlue,
      );
    }
    if (driver.isAvailable) {
      return StatusChip(
        label: l10n.attendanceFilterCheckedIn,
        color: AppColors.success,
      );
    }
    return StatusChip(
      label: l10n.attendanceFilterNotCheckedIn,
      color: AppColors.warning,
    );
  }
}
