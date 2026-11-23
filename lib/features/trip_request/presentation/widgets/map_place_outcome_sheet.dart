import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/features/place/domain/entities/picked_location.dart';
import 'package:teletech_drivers/features/place/presentation/validation/place_validators.dart';
import 'package:teletech_drivers/features/place/domain/entities/place.dart';
import 'package:teletech_drivers/features/trip_request/presentation/models/place_selection.dart';

/// Result of naming a map-picked location and choosing trip-only vs save.
sealed class MapPlaceOutcome {
  const MapPlaceOutcome();
}

/// Use the custom map point for this trip only (no saved place).
final class MapPlaceUseForTripOnly extends MapPlaceOutcome {
  const MapPlaceUseForTripOnly(this.selection);

  final CustomPlaceSelection selection;
}

/// Persist as an approved place (caller must have create permission).
final class MapPlaceSaveAsPlace extends MapPlaceOutcome {
  const MapPlaceSaveAsPlace({
    required this.nameEn,
    required this.nameAr,
    required this.location,
  });

  final String nameEn;
  final String nameAr;
  final PickedLocation location;
}

/// Asks for names, then trip-only vs save-as-place (save only when [canSavePlace]).
Future<MapPlaceOutcome?> showMapPlaceOutcomeSheet({
  required BuildContext context,
  required PickedLocation location,
  required bool canSavePlace,
  List<Place> existingPlaces = const [],
}) {
  return showModalBottomSheet<MapPlaceOutcome>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return _MapPlaceOutcomeSheet(
        location: location,
        canSavePlace: canSavePlace,
        existingPlaces: existingPlaces,
      );
    },
  );
}

class _MapPlaceOutcomeSheet extends StatefulWidget {
  const _MapPlaceOutcomeSheet({
    required this.location,
    required this.canSavePlace,
    required this.existingPlaces,
  });

  final PickedLocation location;
  final bool canSavePlace;
  final List<Place> existingPlaces;

  @override
  State<_MapPlaceOutcomeSheet> createState() => _MapPlaceOutcomeSheetState();
}

class _MapPlaceOutcomeSheetState extends State<_MapPlaceOutcomeSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameEnController;
  late final TextEditingController _nameArController;

  @override
  void initState() {
    super.initState();
    final prefill = widget.location.address?.trim() ?? '';
    final clipped = prefill.length <= CustomPlaceSelection.maxNameLength
        ? prefill
        : prefill.substring(0, CustomPlaceSelection.maxNameLength);
    _nameEnController = TextEditingController(text: clipped);
    _nameArController = TextEditingController();
  }

  @override
  void dispose() {
    _nameEnController.dispose();
    _nameArController.dispose();
    super.dispose();
  }

  void _useForTripOnly() {
    final l10n = AppLocalizations.of(context);
    final name = _nameEnController.text.trim();
    if (name.isEmpty) {
      _formKey.currentState?.validate();
      return;
    }
    if (name.length > CustomPlaceSelection.maxNameLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.validationCustomPlaceRequired)),
      );
      return;
    }
    Navigator.of(context).pop(
      MapPlaceUseForTripOnly(
        CustomPlaceSelection(
          name,
          widget.location.lat,
          widget.location.lng,
          widget.location.address,
        ),
      ),
    );
  }

  void _saveAsPlace() {
    if (!widget.canSavePlace) return;
    final formValid = _formKey.currentState?.validate() ?? false;
    if (!formValid) return;

    final nameEn = _nameEnController.text.trim();
    var nameAr = _nameArController.text.trim();
    if (nameAr.isEmpty) nameAr = nameEn;

    Navigator.of(context).pop(
      MapPlaceSaveAsPlace(
        nameEn: nameEn,
        nameAr: nameAr,
        location: widget.location,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final address = widget.location.address?.trim();

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(20, 0, 20, 20 + bottomInset),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.nameMapPlaceTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (address != null && address.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  address,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameEnController,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.sentences,
                maxLength: CustomPlaceSelection.maxNameLength,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(
                    CustomPlaceSelection.maxNameLength,
                  ),
                ],
                decoration: InputDecoration(
                  labelText: l10n.placeNameEnLabel,
                  border: const OutlineInputBorder(),
                  counterText: '',
                ),
                validator: (value) {
                  if (!widget.canSavePlace) {
                    final trimmed = value?.trim() ?? '';
                    if (trimmed.isEmpty) {
                      return l10n.validationCustomPlaceRequired;
                    }
                    return null;
                  }
                  return PlaceValidators.nameEn(
                    value,
                    l10n,
                    existingPlaces: widget.existingPlaces,
                  );
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameArController,
                textInputAction: TextInputAction.done,
                textCapitalization: TextCapitalization.sentences,
                maxLength: CustomPlaceSelection.maxNameLength,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(
                    CustomPlaceSelection.maxNameLength,
                  ),
                ],
                decoration: InputDecoration(
                  labelText: l10n.placeNameArOptionalLabel,
                  border: const OutlineInputBorder(),
                  counterText: '',
                ),
                validator: widget.canSavePlace
                    ? (value) {
                        final trimmed = value?.trim() ?? '';
                        if (trimmed.isEmpty) return null;
                        return PlaceValidators.nameAr(
                          trimmed,
                          l10n,
                          existingPlaces: widget.existingPlaces,
                        );
                      }
                    : null,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _useForTripOnly,
                child: Text(l10n.useLocationForTripOnly),
              ),
              if (widget.canSavePlace) ...[
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _saveAsPlace,
                  child: Text(l10n.saveLocationAsPlace),
                ),
              ],
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.dialogCancel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
