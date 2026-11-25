import 'package:flutter/material.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/core/widgets/status_chip.dart';
import 'package:teletech_drivers/core/widgets/surface_card.dart';
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

    final name = driver.localizedName(languageCode);
    final muted = textTheme.bodySmall?.copyWith(color: AppColors.inkMuted);

    return SurfaceCard(
      child: ListTile(
      onTap: onOpenDetails,
      contentPadding: const EdgeInsetsDirectional.fromSTEB(14, 8, 6, 8),
      leading: InitialsAvatar(
        name: name,
        statusColor: !driver.isActive
            ? AppColors.inkMuted
            : onTrip
            ? AppColors.signal
            : driver.isAvailable
            ? AppColors.success
            : AppColors.warning,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleSmall,
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          _availabilityChip(l10n),
          const SizedBox(height: 6),
          Text(driver.email, style: muted),
          Text(driver.phone, style: muted),
          Text(nationalIdLine, style: muted),
          Text(statusLabel, style: muted),
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
