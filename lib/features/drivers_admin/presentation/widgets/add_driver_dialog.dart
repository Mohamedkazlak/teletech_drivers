import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/presentation/app_loading_indicator.dart';
import 'package:teletech_drivers/core/utils/failure_messages.dart';
import 'package:teletech_drivers/features/auth/presentation/validation/auth_validators.dart';
import 'package:teletech_drivers/features/auth/presentation/widgets/auth_error_banner.dart';
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
    return showDialog<bool>(
      context: context,
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
    if (!formValid || plate == null) return;

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

    return AlertDialog(
      title: Text(l10n.addDriverTitle),
      content: Form(
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
                  labelText: l10n.driverNameEnLabel,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) => DriverValidators.nameEn(value, l10n),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameArController,
                enabled: !formState.isLoading,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: l10n.driverNameArLabel,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) => DriverValidators.nameAr(value, l10n),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                enabled: !formState.isLoading,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: l10n.emailLabel,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) => DriverValidators.email(value, l10n),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                enabled: !formState.isLoading,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: l10n.phoneLabel,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) => DriverValidators.phone(value, l10n),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nationalIdController,
                enabled: !formState.isLoading,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(
                    DriverValidators.egyptNationalIdLength,
                  ),
                ],
                decoration: InputDecoration(
                  labelText: l10n.nationalIdLabel,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) => DriverValidators.nationalId(value, l10n),
              ),
              const SizedBox(height: 12),
              CarPlateFields(
                lettersController: _plateLettersController,
                numbersController: _plateNumbersController,
                enabled: !formState.isLoading,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _personalLicenseController,
                enabled: !formState.isLoading,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: l10n.personalLicenseLabel,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) =>
                    DriverValidators.personalLicense(value, l10n),
              ),
              const SizedBox(height: 12),
              placesAsync.when(
                loading: () => AppLoadingIndicator(label: l10n.loading),
                error: (error, _) => Text(messageForError(error, l10n)),
                data: (List<Place> places) => FavoritePlacesField(
                  places: places,
                  selectedPlaceIds: _favoritePlaceIds,
                  enabled: !formState.isLoading,
                  onChanged: (ids) => setState(() => _favoritePlaceIds = ids),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                enabled: !formState.isLoading,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: l10n.temporaryPasswordLabel,
                  helperText: l10n.driverMustChangePasswordNote,
                  helperMaxLines: 3,
                  border: const OutlineInputBorder(),
                  suffixIcon: PasswordVisibilityButton(
                    obscure: _obscurePassword,
                    onPressed: formState.isLoading
                        ? null
                        : () => setState(() {
                            _obscurePassword = !_obscurePassword;
                          }),
                  ),
                ),
                validator: (value) => AuthValidators.password(value, l10n),
                onFieldSubmitted: (_) {
                  if (!formState.isLoading) _submit();
                },
              ),
            ],
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
          onPressed: formState.isLoading ? null : _submit,
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
              : Text(l10n.addDriver),
        ),
      ],
    );
  }
}
