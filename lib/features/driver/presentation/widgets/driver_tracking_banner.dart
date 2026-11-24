import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/core/theme/app_theme.dart';
import 'package:teletech_drivers/features/tracking/presentation/controllers/location_tracking_controller.dart';
import 'package:teletech_drivers/features/tracking/presentation/utils/location_sharing_message.dart';

/// GPS-sharing warning shown on the driver shell tabs.
class DriverTrackingBanner extends ConsumerWidget {
  const DriverTrackingBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tracking = ref.watch(locationTrackingControllerProvider);
    if (!tracking.warningBanner) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 16, 12),
      child: Material(
        color: AppColors.error.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          side: BorderSide(color: AppColors.error.withValues(alpha: 0.24)),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          leading: const Icon(Icons.gps_off_rounded, color: AppColors.error),
          title: Text(
            locationSharingBannerText(l10n, tracking),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.inkOn(AppColors.error),
              fontWeight: FontWeight.w500,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right,
            color: AppColors.inkOn(AppColors.error),
          ),
          onTap: () {
            ref.read(locationTrackingControllerProvider.notifier).fixSharing();
          },
        ),
      ),
    );
  }
}
