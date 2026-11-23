import 'package:flutter/material.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';

/// Small badge for trip pickup/destination chosen on the map.
class CustomLocationChip extends StatelessWidget {
  const CustomLocationChip({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Chip(
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      avatar: const Icon(Icons.map_outlined, size: 16, color: AppColors.deepBlue),
      label: Text(
        l10n.customLocationChip,
        style: Theme.of(context).textTheme.labelSmall,
      ),
      side: BorderSide(color: AppColors.midBlue.withValues(alpha: 0.4)),
      backgroundColor: AppColors.paleBlue,
      padding: EdgeInsets.zero,
      labelPadding: const EdgeInsetsDirectional.only(end: 6),
    );
  }
}
