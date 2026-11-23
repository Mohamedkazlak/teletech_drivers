import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
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
      padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 8),
      child: Material(
        color: AppColors.warning.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          leading: const Icon(Icons.gps_off, color: AppColors.error),
          title: Text(locationSharingBannerText(l10n, tracking)),
          onTap: () {
            ref.read(locationTrackingControllerProvider.notifier).fixSharing();
          },
        ),
      ),
    );
  }
}
