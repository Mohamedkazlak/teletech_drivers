import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/utils/failure_messages.dart';
import 'package:teletech_drivers/features/auth/presentation/widgets/auth_error_banner.dart';
import 'package:teletech_drivers/features/place/domain/entities/place.dart';
import 'package:teletech_drivers/features/place/presentation/controllers/place_form_controller.dart';
import 'package:teletech_drivers/features/place/presentation/validation/place_validators.dart';
import 'package:teletech_drivers/features/place/presentation/widgets/place_coordinate_picker.dart';

/// Add or edit place dialog with names and required map coordinates.
class PlaceFormDialog extends ConsumerStatefulWidget {
  const PlaceFormDialog({required this.existingPlaces, this.place, super.key});

  final List<Place> existingPlaces;
  final Place? place;

  static Future<bool?> show(
    BuildContext context, {
    required List<Place> existingPlaces,
    Place? place,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) =>
          PlaceFormDialog(existingPlaces: existingPlaces, place: place),
    );
  }

  @override
  ConsumerState<PlaceFormDialog> createState() => _PlaceFormDialogState();
}

class _PlaceFormDialogState extends ConsumerState<PlaceFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameEnController;
  late final TextEditingController _nameArController;
  late final TextEditingController _addressController;
  late final TextEditingController _latController;
  late final TextEditingController _lngController;
  double? _latitude;
  double? _longitude;
  var _manualCoordsExpanded = false;

  bool get _isEditing => widget.place != null;

  bool get _hasLocation =>
      _latitude != null &&
      _longitude != null &&
      PlaceValidators.isValidLatitude(_latitude!) &&
      PlaceValidators.isValidLongitude(_longitude!);

  @override
  void initState() {
    super.initState();
    _nameEnController = TextEditingController(text: widget.place?.nameEn ?? '');
    _nameArController = TextEditingController(text: widget.place?.nameAr ?? '');
    _addressController = TextEditingController(text: widget.place?.address ?? '');
    _latitude = widget.place?.latitude;
    _longitude = widget.place?.longitude;
    _latController = TextEditingController(
      text: _latitude == null ? '' : _latitude!.toStringAsFixed(6),
    );
    _lngController = TextEditingController(
      text: _longitude == null ? '' : _longitude!.toStringAsFixed(6),
    );
  }

  @override
  void dispose() {
    _nameEnController.dispose();
    _nameArController.dispose();
    _addressController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  void _setPickedLocation({
    required double latitude,
    required double longitude,
  }) {
    setState(() {
      _latitude = latitude;
      _longitude = longitude;
      _latController.text = latitude.toStringAsFixed(6);
      _lngController.text = longitude.toStringAsFixed(6);
    });
  }

  void _clearLocation() {
    setState(() {
      _latitude = null;
      _longitude = null;
      _latController.text = '';
      _lngController.text = '';
    });
  }

  void _onLatLngFieldsChanged() {
    final lat = double.tryParse(_latController.text.trim());
    final lng = double.tryParse(_lngController.text.trim());
    if (lat == null || lng == null) {
      setState(() {
        _latitude = null;
        _longitude = null;
      });
      return;
    }
    if (!PlaceValidators.isValidLatitude(lat) ||
        !PlaceValidators.isValidLongitude(lng)) {
      return;
    }
    setState(() {
      _latitude = lat;
      _longitude = lng;
    });
  }

  String? _coordinateFieldError(
    String? value, {
    required bool isLatitude,
    required AppLocalizations l10n,
  }) {
    final latText = _latController.text.trim();
    final lngText = _lngController.text.trim();
    if (latText.isEmpty && lngText.isEmpty) return null;
    final text = value?.trim() ?? '';
    if (text.isEmpty) return l10n.validationPlaceCoordinatePair;
    final parsed = double.tryParse(text);
    if (parsed == null) {
      return isLatitude
          ? l10n.validationLatitudeInvalid
          : l10n.validationLongitudeInvalid;
    }
    if (isLatitude && !PlaceValidators.isValidLatitude(parsed)) {
      return l10n.validationLatitudeInvalid;
    }
    if (!isLatitude && !PlaceValidators.isValidLongitude(parsed)) {
      return l10n.validationLongitudeInvalid;
    }
    return null;
  }

  Future<void> _submit() async {
    final formValid = _formKey.currentState?.validate() ?? false;
    if (!formValid) return;

    ref.read(placeFormControllerProvider.notifier).clearFailure();

    // Headquarters is seeded once; company admin cannot set it from this form.
    final isHeadquarters = widget.place?.isHeadquarters ?? false;
    final notifier = ref.read(placeFormControllerProvider.notifier);
    final succeeded = _isEditing
        ? await notifier.edit(
            placeId: widget.place!.id,
            nameEn: _nameEnController.text,
            nameAr: _nameArController.text,
            address: _addressController.text,
            latitude: _hasLocation ? _latitude : null,
            longitude: _hasLocation ? _longitude : null,
            isHeadquarters: isHeadquarters,
          )
        : await notifier.add(
            nameEn: _nameEnController.text,
            nameAr: _nameArController.text,
            address: _addressController.text,
            latitude: _hasLocation ? _latitude : null,
            longitude: _hasLocation ? _longitude : null,
            isHeadquarters: isHeadquarters,
          );

    if (!mounted || !succeeded) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final formState = ref.watch(placeFormControllerProvider);
    final excludingId = widget.place?.id;
    final media = MediaQuery.sizeOf(context);
    final canSave = !formState.isLoading;

    return AlertDialog(
      title: Text(_isEditing ? l10n.editPlaceTitle : l10n.addPlaceTitle),
      content: SizedBox(
        width: media.width > 480 ? 420 : media.width * 0.92,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (formState.failure != null) ...[
                  AuthErrorBanner(message: formState.failure!.message(l10n)),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _nameEnController,
                  enabled: !formState.isLoading,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: l10n.placeNameEnLabel,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) => PlaceValidators.nameEn(
                    value,
                    l10n,
                    existingPlaces: widget.existingPlaces,
                    excludingPlaceId: excludingId,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameArController,
                  enabled: !formState.isLoading,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: l10n.placeNameArLabel,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) => PlaceValidators.nameAr(
                    value,
                    l10n,
                    existingPlaces: widget.existingPlaces,
                    excludingPlaceId: excludingId,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  enabled: !formState.isLoading,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: l10n.placeAddressLabel,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) => PlaceValidators.address(value, l10n),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.placeLocationOptionalHint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
                ),
                const SizedBox(height: 8),
                PlaceCoordinatePicker(
                  latitude: _latitude,
                  longitude: _longitude,
                  enabled: !formState.isLoading,
                  onChanged: (picked) => _setPickedLocation(
                    latitude: picked.lat,
                    longitude: picked.lng,
                  ),
                ),
                if (_hasLocation)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton(
                      onPressed: formState.isLoading ? null : _clearLocation,
                      child: Text(l10n.clearPlaceLocation),
                    ),
                  ),
                const SizedBox(height: 8),
                ExpansionTile(
                  initiallyExpanded: _manualCoordsExpanded,
                  onExpansionChanged: (expanded) {
                    setState(() => _manualCoordsExpanded = expanded);
                  },
                  tilePadding: EdgeInsets.zero,
                  title: Text(
                    l10n.enterCoordinatesManually,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _latController,
                            enabled: !formState.isLoading,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[-0-9.]'),
                              ),
                            ],
                            decoration: InputDecoration(
                              labelText: l10n.latitudeLabel,
                              border: const OutlineInputBorder(),
                            ),
                            onChanged: (_) => _onLatLngFieldsChanged(),
                            validator: (value) => _coordinateFieldError(
                              value,
                              isLatitude: true,
                              l10n: l10n,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _lngController,
                            enabled: !formState.isLoading,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[-0-9.]'),
                              ),
                            ],
                            decoration: InputDecoration(
                              labelText: l10n.longitudeLabel,
                              border: const OutlineInputBorder(),
                            ),
                            onChanged: (_) => _onLatLngFieldsChanged(),
                            validator: (value) => _coordinateFieldError(
                              value,
                              isLatitude: false,
                              l10n: l10n,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: formState.isLoading
              ? null
              : () => Navigator.of(context).pop(false),
          child: Text(l10n.dialogCancel),
        ),
        FilledButton(
          onPressed: canSave ? _submit : null,
          child: formState.isLoading
              ? SizedBox.square(
                  dimension: 20,
                  child: Semantics(
                    label: l10n.loading,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                )
              : Text(_isEditing ? l10n.savePlace : l10n.addPlace),
        ),
      ],
    );
  }
}
