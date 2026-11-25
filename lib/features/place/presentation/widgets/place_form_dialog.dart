import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/utils/failure_messages.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/core/widgets/form_section.dart';
import 'package:teletech_drivers/core/widgets/form_sheet.dart';
import 'package:teletech_drivers/features/place/domain/entities/place.dart';
import 'package:teletech_drivers/features/place/presentation/controllers/place_form_controller.dart';
import 'package:teletech_drivers/features/place/presentation/validation/place_validators.dart';
import 'package:teletech_drivers/core/theme/app_motion.dart';
import 'package:teletech_drivers/core/widgets/animation_helpers.dart';
import 'package:teletech_drivers/features/place/domain/entities/picked_location.dart';
import 'package:teletech_drivers/features/place/presentation/widgets/place_location_card.dart';

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
    return showFormSheet<bool>(
      context,
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
  var _shake = 0;
  late var _step = widget.place == null ? 0 : 1;
  var _addressFromMap = false;

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

  void _setPicked(PickedLocation picked) {
    setState(() {
      _latitude = picked.lat;
      _longitude = picked.lng;
      _latController.text = picked.lat.toStringAsFixed(6);
      _lngController.text = picked.lng.toStringAsFixed(6);
      // Save the user typing: the address comes from the map unless set.
      final found = picked.address?.trim();
      if (found != null &&
          found.isNotEmpty &&
          (_addressController.text.trim().isEmpty || _addressFromMap)) {
        _addressController.text = found;
        _addressFromMap = true;
      }
    });
  }

  void _goToStep(int step) {
    if (step == _step) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _step = step);
  }

  void _continueFromLocation() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      setState(() => _shake++);
      return;
    }
    _goToStep(1);
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
    if (!formValid) {
      setState(() => _shake++);
      return;
    }

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
    final busy = formState.isLoading;
    final textTheme = Theme.of(context).textTheme;
    final onLocationStep = _step == 0;
    return FormSheet(
      title: _isEditing ? l10n.editPlaceTitle : l10n.addPlaceTitle,
      icon: _isEditing
          ? Icons.edit_location_alt_outlined
          : Icons.add_location_alt_outlined,
      formKey: _formKey,
      isLoading: busy,
      shakeTrigger: _shake,
      stepKey: _step,
      headerBottom: _StepHeader(
        step: _step,
        labels: [l10n.placeStepLocation, l10n.placeStepDetails],
        onTap: busy ? null : _goToStep,
      ),
      errorMessage: formState.failure?.message(l10n),
      secondaryLabel: onLocationStep ? null : l10n.onboardingBack,
      onSecondary: onLocationStep ? null : () => _goToStep(0),
      primaryLabel: onLocationStep
          ? (_hasLocation ? l10n.placeContinue : l10n.placeSkipLocation)
          : (_isEditing ? l10n.savePlace : l10n.addPlace),
      onPrimary: onLocationStep ? _continueFromLocation : _submit,
      children: onLocationStep
          ? [
              PlaceLocationCard(
                latitude: _hasLocation ? _latitude : null,
                longitude: _hasLocation ? _longitude : null,
                address: _addressController.text,
                enabled: !busy,
                onPicked: _setPicked,
                onClear: _clearLocation,
              ),
              Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  initiallyExpanded: _manualCoordsExpanded,
                  onExpansionChanged: (expanded) {
                    setState(() => _manualCoordsExpanded = expanded);
                  },
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.only(bottom: 4),
                  title: Text(
                    l10n.enterCoordinatesManually,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.inkMuted,
                    ),
                  ),
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _coordField(
                            controller: _latController,
                            label: l10n.latitudeLabel,
                            busy: busy,
                            isLatitude: true,
                            l10n: l10n,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _coordField(
                            controller: _lngController,
                            label: l10n.longitudeLabel,
                            busy: busy,
                            isLatitude: false,
                            l10n: l10n,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ]
          : [
              FormSection(
                title: l10n.formSectionPlace,
                icon: Icons.storefront_outlined,
                children: [
                  TextFormField(
                    controller: _nameEnController,
                    enabled: !busy,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: l10n.placeNameEnLabel,
                    ),
                    validator: (value) => PlaceValidators.nameEn(
                      value,
                      l10n,
                      existingPlaces: widget.existingPlaces,
                      excludingPlaceId: excludingId,
                    ),
                  ),
                  TextFormField(
                    controller: _nameArController,
                    enabled: !busy,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: l10n.placeNameArLabel,
                    ),
                    validator: (value) => PlaceValidators.nameAr(
                      value,
                      l10n,
                      existingPlaces: widget.existingPlaces,
                      excludingPlaceId: excludingId,
                    ),
                  ),
                  TextFormField(
                    controller: _addressController,
                    enabled: !busy,
                    textInputAction: TextInputAction.done,
                    minLines: 1,
                    maxLines: 3,
                    onChanged: (_) => _addressFromMap = false,
                    decoration: InputDecoration(
                      labelText: l10n.placeAddressLabel,
                      prefixIcon: const Icon(Icons.signpost_outlined),
                      helperText: _addressFromMap
                          ? l10n.placeAddressFilled
                          : null,
                    ),
                    validator: (value) =>
                        PlaceValidators.address(value, l10n),
                  ),
                ],
              ),
            ],
    );
  }

  Widget _coordField({
    required TextEditingController controller,
    required String label,
    required bool busy,
    required bool isLatitude,
    required AppLocalizations l10n,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !busy,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      ),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[-0-9.]'))],
      decoration: InputDecoration(labelText: label),
      onChanged: (_) => _onLatLngFieldsChanged(),
      validator: (value) =>
          _coordinateFieldError(value, isLatitude: isLatitude, l10n: l10n),
    );
  }
}

/// Two-step indicator: numbered discs joined by a line that fills as you move
/// on. Finished steps show a check and can be tapped to go back.
class _StepHeader extends StatelessWidget {
  const _StepHeader({
    required this.step,
    required this.labels,
    required this.onTap,
  });

  final int step;
  final List<String> labels;
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) {
    final duration = AppAnimations.duration(context, AppMotion.emphasized);
    final style = Theme.of(context).textTheme.labelMedium;
    Widget disc(int i) {
      final done = i < step;
      final active = i == step;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap == null ? null : () => onTap!(i),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: duration,
              curve: AppMotion.easeOut,
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done || active ? AppColors.deepBlue : AppColors.white,
                border: Border.all(
                  color: done || active ? AppColors.deepBlue : AppColors.line,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: done
                    ? const Icon(Icons.check, size: 16, color: AppColors.white)
                    : Text(
                        '${i + 1}',
                        style: style?.copyWith(
                          color: active ? AppColors.white : AppColors.inkMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              labels[i],
              style: style?.copyWith(
                color: active || done ? AppColors.navy : AppColors.inkMuted,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: [
          disc(0),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: step >= 1 ? 1 : 0),
                  duration: duration,
                  curve: AppMotion.easeInOut,
                  builder: (context, value, _) => LinearProgressIndicator(
                    value: value,
                    minHeight: 3,
                    backgroundColor: AppColors.line,
                    color: AppColors.deepBlue,
                  ),
                ),
              ),
            ),
          ),
          disc(1),
        ],
      ),
    );
  }
}
