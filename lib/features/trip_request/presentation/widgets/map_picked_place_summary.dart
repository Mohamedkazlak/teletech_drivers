import 'package:flutter/material.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/features/place/presentation/widgets/place_preview_map.dart';
import 'package:teletech_drivers/features/trip_request/presentation/models/place_selection.dart';
import 'package:teletech_drivers/features/trip_request/presentation/widgets/custom_location_chip.dart';

/// Summary card shown when pickup/destination was chosen on the map.
class MapPickedPlaceSummary extends StatelessWidget {
  const MapPickedPlaceSummary({
    required this.selection,
    required this.onClear,
    this.enabled = true,
    super.key,
  });

  final CustomPlaceSelection selection;
  final VoidCallback onClear;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final address = selection.address?.trim();
    final coords = selection.hasCoordinates
        ? '${selection.lat!.toStringAsFixed(5)}, '
              '${selection.lng!.toStringAsFixed(5)}'
        : null;

    return Container(
      padding: const EdgeInsetsDirectional.all(12),
      decoration: BoxDecoration(
        color: AppColors.paleBlue,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.midBlue.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  selection.trimmedName,
                  style: Theme.of(context).textTheme.titleSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const CustomLocationChip(),
              if (enabled)
                IconButton(
                  tooltip: l10n.dialogCancel,
                  onPressed: onClear,
                  icon: const Icon(Icons.close),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          if (address != null && address.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              address,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (coords != null) ...[
            const SizedBox(height: 2),
            Text(
              coords,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).hintColor,
              ),
            ),
          ],
          OptionalPlacePreviewMap(
            latitude: selection.lat,
            longitude: selection.lng,
            height: 120,
          ),
        ],
      ),
    );
  }
}
