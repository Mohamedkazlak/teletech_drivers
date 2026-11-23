import 'package:flutter/material.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/features/place/domain/entities/place.dart';
import 'package:teletech_drivers/features/place/presentation/widgets/place_preview_map.dart';

/// One place row with active switch, edit, and delete actions.
class PlaceListTile extends StatelessWidget {
  const PlaceListTile({
    required this.place,
    required this.isToggling,
    required this.isDeleting,
    required this.onActiveChanged,
    required this.onEdit,
    required this.onDelete,
    super.key,
  });

  final Place place;
  final bool isToggling;
  final bool isDeleting;
  final ValueChanged<bool> onActiveChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final primaryName = place.displayName(languageCode);
    final secondaryName = languageCode == 'ar'
        ? place.nameEn.trim()
        : place.nameAr.trim();
    final status = place.isActive
        ? l10n.placeStatusActive
        : l10n.placeStatusInactive;
    final busy = isToggling || isDeleting;

    return ListTile(
      contentPadding: const EdgeInsetsDirectional.fromSTEB(8, 0, 0, 0),
      onTap: busy ? null : onEdit,
      title: Text(primaryName),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (secondaryName.isNotEmpty) Text(secondaryName),
          Text(status),
          if (place.isHeadquarters)
            Text(
              l10n.placeHeadquartersBadge,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          const SizedBox(height: 4),
          if (place.hasCoordinates) ...[
            Text(
              l10n.placeHasCoordinates,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            OptionalPlacePreviewMap(
              latitude: place.latitude,
              longitude: place.longitude,
              height: 96,
              topSpacing: 6,
            ),
          ] else
            InkWell(
              onTap: busy ? null : onEdit,
              borderRadius: BorderRadius.circular(16),
              child: Chip(
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                avatar: Icon(
                  Icons.warning_amber_rounded,
                  size: 16,
                  color: AppColors.midBlue,
                ),
                label: Text(
                  l10n.noLocationBadge,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                backgroundColor: AppColors.paleBlue,
                side: BorderSide(
                  color: AppColors.midBlue.withValues(alpha: 0.35),
                ),
                padding: EdgeInsets.zero,
                labelPadding: const EdgeInsetsDirectional.symmetric(
                  horizontal: 6,
                ),
              ),
            ),
        ],
      ),
      isThreeLine: true,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (busy)
            const Padding(
              padding: EdgeInsetsDirectional.only(end: 12),
              child: SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else ...[
            Switch.adaptive(value: place.isActive, onChanged: onActiveChanged),
            IconButton(
              tooltip: l10n.editPlace,
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: l10n.deletePlace,
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ],
      ),
    );
  }
}
