import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/presentation/app_loading_indicator.dart';
import 'package:teletech_drivers/core/utils/failure_messages.dart';
import 'package:teletech_drivers/features/auth/presentation/validation/auth_validators.dart';
import 'package:teletech_drivers/core/widgets/form_section.dart';
import 'package:teletech_drivers/core/widgets/form_sheet.dart';
import 'package:teletech_drivers/features/auth/presentation/widgets/password_visibility_button.dart';
import 'package:teletech_drivers/features/drivers_admin/domain/egyptian_car_plate.dart';
import 'package:teletech_drivers/features/drivers_admin/presentation/controllers/create_driver_controller.dart';
import 'package:teletech_drivers/features/drivers_admin/presentation/validation/driver_validators.dart';
import 'package:teletech_drivers/features/drivers_admin/presentation/widgets/car_plate_fields.dart';
import 'package:teletech_drivers/features/drivers_admin/presentation/widgets/favorite_places_field.dart';
import 'package:teletech_drivers/features/place/domain/entities/place.dart';
import 'package:teletech_drivers/features/place/presentation/providers/place_providers.dart';

/// Form to create a driver account.
class AddDriverDialog extends ConsumerStatefulWidget {
  const AddDriverDialog({super.key});

  static Future<bool?> show(BuildContext context) {
    return showFormSheet<bool>(
      context,
      builder: (_) => const AddDriverDialog(),
    );
  }

  @override
  ConsumerState<AddDriverDialog> createState() => _AddDriverDialogState();
}

class _AddDriverDialogState extends ConsumerState<AddDriverDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameEnController = TextEditingController();
  final _nameArController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _plateLettersController = TextEditingController();
  final _plateNumbersController = TextEditingController();
  final _personalLicenseController = TextEditingController();
  final _passwordController = TextEditingController();
  var _obscurePassword = true;
  var _favoritePlaceIds = <String>[];
  var _shake = 0;

  @override
  void dispose() {
    _nameEnController.dispose();
    _nameArController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _nationalIdController.dispose();
    _plateLettersController.dispose();
    _plateNumbersController.dispose();
    _personalLicenseController.dispose();
    _passwordController.dispose();
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

    ref.read(createDriverControllerProvider.notifier).clearFailure();

    final succeeded = await ref
        .read(createDriverControllerProvider.notifier)
        .submit(
          nameEn: _nameEnController.text,
          nameAr: _nameArController.text,
          email: _emailController.text,
          password: _passwordController.text,
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
    final formState = ref.watch(createDriverControllerProvider);
    final placesAsync = ref.watch(activePlacesProvider);

    final busy = formState.isLoading;
    return FormSheet(
      title: l10n.addDriverTitle,
      icon: Icons.local_taxi_outlined,
      formKey: _formKey,
      isLoading: busy,
      shakeTrigger: _shake,
      errorMessage: formState.failure?.message(l10n),
      primaryLabel: l10n.addDriver,
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
              controller: _emailController,
              enabled: !busy,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: l10n.emailLabel,
                prefixIcon: const Icon(Icons.email_outlined),
              ),
              validator: (value) => DriverValidators.email(value, l10n),
            ),
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
              textInputAction: TextInputAction.next,
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
        FormSection(
          title: l10n.formSectionAccess,
          icon: Icons.lock_outline_rounded,
          children: [
            TextFormField(
              controller: _passwordController,
              enabled: !busy,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: l10n.temporaryPasswordLabel,
                helperText: l10n.driverMustChangePasswordNote,
                suffixIcon: PasswordVisibilityButton(
                  obscure: _obscurePassword,
                  onPressed: busy
                      ? null
                      : () => setState(() {
                          _obscurePassword = !_obscurePassword;
                        }),
                ),
              ),
              validator: (value) => AuthValidators.password(value, l10n),
              onFieldSubmitted: (_) {
                if (!busy) _submit();
              },
            ),
          ],
        ),
      ],
    );
  }
}
