import 'package:flutter/material.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/features/tracking/presentation/state/location_tracking_state.dart';

/// Top chip: sharing vs location-off (tappable to fix).
class TrackingStatusChip extends StatelessWidget {
  const TrackingStatusChip({
    required this.status,
    this.onFix,
    super.key,
  });

  final LocationTrackingStatus status;
  final VoidCallback? onFix;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sharing = status == LocationTrackingStatus.sharing;
    final label = sharing
        ? l10n.sharingLocation
        : l10n.locationOffTapToFix;
    final color = sharing ? AppColors.success : AppColors.error;

    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: sharing ? null : onFix,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                sharing ? Icons.gps_fixed : Icons.gps_off,
                size: 16,
                color: color,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
