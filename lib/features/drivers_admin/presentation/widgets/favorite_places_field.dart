import 'package:flutter/material.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/features/place/domain/entities/place.dart';
import 'package:teletech_drivers/features/trip_request/presentation/models/place_selection.dart';
import 'package:teletech_drivers/features/trip_request/presentation/widgets/place_search_dropdown.dart';

/// Multi-select favorite places using the searchable place dropdown + chips.
class FavoritePlacesField extends StatelessWidget {
  const FavoritePlacesField({
    required this.places,
    required this.selectedPlaceIds,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  final List<Place> places;
  final List<String> selectedPlaceIds;
  final ValueChanged<List<String>> onChanged;
  final bool enabled;

  Place? _placeById(String id) {
    for (final place in places) {
      if (place.id == id) return place;
    }
    return null;
  }

  static const maxPlaces = 5;

  void _addPlace(Place place) {
    if (selectedPlaceIds.contains(place.id)) return;
    if (selectedPlaceIds.length >= maxPlaces) return;
    onChanged([...selectedPlaceIds, place.id]);
  }

  void _removePlace(String placeId) {
    onChanged([
      for (final id in selectedPlaceIds)
        if (id != placeId) id,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final selectedIds = selectedPlaceIds.toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.favoritePlacesLimit, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        PlaceSearchDropdown(
          key: ValueKey('favorites-${selectedPlaceIds.join(',')}'),
          places: places,
          label: l10n.favoritePlacesLabel,
          searchHint: l10n.favoritePlacesSearchHint,
          enabled: enabled && selectedPlaceIds.length < maxPlaces,
          includeOtherOption: false,
          requireCoordinates: false,
          excludePlaceIds: selectedIds,
          onSelected: (selection) {
            if (selection is ApprovedPlaceSelection) {
              _addPlace(selection.place);
            }
          },
        ),
        if (selectedPlaceIds.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final id in selectedPlaceIds)
                InputChip(
                  label: Text(_placeById(id)?.displayName(languageCode) ?? id),
                  onDeleted: enabled ? () => _removePlace(id) : null,
                  deleteButtonTooltipMessage: l10n.favoritePlaceRemove,
                ),
            ],
          ),
        ],
      ],
    );
  }
}
