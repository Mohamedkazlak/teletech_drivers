import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/presentation/app_loading_indicator.dart';
import 'package:teletech_drivers/core/utils/failure_messages.dart';
import 'package:teletech_drivers/core/widgets/form_section.dart';
import 'package:teletech_drivers/core/widgets/form_sheet.dart';
import 'package:teletech_drivers/features/drivers_admin/domain/egyptian_car_plate.dart';
import 'package:teletech_drivers/features/drivers_admin/domain/entities/driver_profile.dart';
import 'package:teletech_drivers/features/drivers_admin/presentation/controllers/update_driver_controller.dart';
import 'package:teletech_drivers/features/drivers_admin/presentation/validation/driver_validators.dart';
import 'package:teletech_drivers/features/drivers_admin/presentation/widgets/car_plate_fields.dart';
import 'package:teletech_drivers/features/drivers_admin/presentation/widgets/favorite_places_field.dart';
import 'package:teletech_drivers/features/place/domain/entities/place.dart';
import 'package:teletech_drivers/features/place/presentation/providers/place_providers.dart';

/// Form to edit public and private driver fields (batch write).
class EditDriverDialog extends ConsumerStatefulWidget {
  const EditDriverDialog({required this.driver, super.key});

  final DriverProfile driver;

  static Future<bool?> show(
    BuildContext context, {
    required DriverProfile driver,
  }) {
    return showFormSheet<bool>(
      context,
      builder: (_) => EditDriverDialog(driver: driver),
    );
  }

  @override
  ConsumerState<EditDriverDialog> createState() => _EditDriverDialogState();
}

class _EditDriverDialogState extends ConsumerState<EditDriverDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameEnController;
  late final TextEditingController _nameArController;
  late final TextEditingController _phoneController;
  late final TextEditingController _nationalIdController;
  late final TextEditingController _plateLettersController;
  late final TextEditingController _plateNumbersController;
  late final TextEditingController _personalLicenseController;
  late List<String> _favoritePlaceIds;
  var _shake = 0;

  @override
  void initState() {
    super.initState();
    final driver = widget.driver;
    _nameEnController = TextEditingController(text: driver.nameEn);
    _nameArController = TextEditingController(text: driver.nameAr);
    _phoneController = TextEditingController(text: driver.phone);
    final plate = EgyptianCarPlate.parts(driver.carLicense);
    _nationalIdController = TextEditingController(text: driver.nationalId);
    _plateLettersController = TextEditingController(text: plate?.letters ?? '');
    _plateNumbersController = TextEditingController(
      text: plate?.numbers ?? '',
    );
    _personalLicenseController = TextEditingController(
      text: driver.personalLicense,
    );
    _favoritePlaceIds = List<String>.of(driver.favoritePlaceIds);
  }

  @override
  void dispose() {
    _nameEnController.dispose();
    _nameArController.dispose();
    _phoneController.dispose();
    _nationalIdController.dispose();
    _plateLettersController.dispose();
    _plateNumbersController.dispose();
    _personalLicenseController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final formValid = _formKey.currentState?.validate() ?? false;
    final plate = EgyptianCarPlate.fromParts(
      _plateLettersController.text,
      _plateNumbersController.text,
    );
    if (!formValid || plate == null) {
      setState(() => _shake++);
      return;
    }

    ref.read(updateDriverControllerProvider.notifier).clearFailure();

    final succeeded = await ref
        .read(updateDriverControllerProvider.notifier)
        .submit(
          driverId: widget.driver.id,
          nameEn: _nameEnController.text,
          nameAr: _nameArController.text,
          phone: _phoneController.text,
          nationalId: _nationalIdController.text,
          carLicense: plate,
          personalLicense: _personalLicenseController.text,
          favoritePlaceIds: _favoritePlaceIds,
        );

    if (!mounted || !succeeded) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final formState = ref.watch(updateDriverControllerProvider);
    final placesAsync = ref.watch(activePlacesProvider);

    final busy = formState.isLoading;
    return FormSheet(
      title: l10n.editDriverTitle,
      subtitle: widget.driver.email,
      icon: Icons.edit_outlined,
      formKey: _formKey,
      isLoading: busy,
      shakeTrigger: _shake,
      errorMessage: formState.failure?.message(l10n),
      primaryLabel: l10n.saveDriver,
      onPrimary: _submit,
      children: [
        FormSection(
          title: l10n.formSectionPersonal,
          icon: Icons.badge_outlined,
          children: [
            TextFormField(
              controller: _nameEnController,
              enabled: !busy,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: l10n.driverNameEnLabel),
              validator: (value) => DriverValidators.nameEn(value, l10n),
            ),
            TextFormField(
              controller: _nameArController,
              enabled: !busy,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: l10n.driverNameArLabel),
              validator: (value) => DriverValidators.nameAr(value, l10n),
            ),
            TextFormField(
              controller: _nationalIdController,
              enabled: !busy,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(
                  DriverValidators.egyptNationalIdLength,
                ),
              ],
              decoration: InputDecoration(labelText: l10n.nationalIdLabel),
              validator: (value) => DriverValidators.nationalId(value, l10n),
            ),
          ],
        ),
        FormSection(
          title: l10n.formSectionContact,
          icon: Icons.alternate_email_rounded,
          children: [
            TextFormField(
              controller: _phoneController,
              enabled: !busy,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: l10n.phoneLabel,
                prefixIcon: const Icon(Icons.phone_outlined),
              ),
              validator: (value) => DriverValidators.phone(value, l10n),
            ),
          ],
        ),
        FormSection(
          title: l10n.formSectionVehicle,
          icon: Icons.directions_car_outlined,
          children: [
            CarPlateFields(
              lettersController: _plateLettersController,
              numbersController: _plateNumbersController,
              enabled: !busy,
            ),
            TextFormField(
              controller: _personalLicenseController,
              enabled: !busy,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: l10n.personalLicenseLabel,
              ),
              validator: (value) =>
                  DriverValidators.personalLicense(value, l10n),
            ),
          ],
        ),
        FormSection(
          title: l10n.formSectionWork,
          icon: Icons.place_outlined,
          children: [
            placesAsync.when(
              loading: () => AppLoadingIndicator(label: l10n.loading),
              error: (error, _) => Text(messageForError(error, l10n)),
              data: (List<Place> places) => FavoritePlacesField(
                places: places,
                selectedPlaceIds: _favoritePlaceIds,
                enabled: !busy,
                onChanged: (ids) => setState(() => _favoritePlaceIds = ids),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
