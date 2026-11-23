import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/features/drivers_admin/domain/egyptian_car_plate.dart';
import 'package:teletech_drivers/features/drivers_admin/presentation/validation/driver_validators.dart';

/// Letters and numbers of an Egyptian car plate, stored as one string.
class CarPlateFields extends StatelessWidget {
  const CarPlateFields({
    required this.lettersController,
    required this.numbersController,
    required this.enabled,
    super.key,
  });

  final TextEditingController lettersController;
  final TextEditingController numbersController;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.carLicenseLabel,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: lettersController,
                enabled: enabled,
                textInputAction: TextInputAction.next,
                textDirection: TextDirection.rtl,
                inputFormatters: const [_PlateLettersFormatter()],
                decoration: InputDecoration(
                  labelText: l10n.carPlateLettersLabel,
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: numbersController,
                enabled: enabled,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                inputFormatters: const [_PlateNumbersFormatter()],
                decoration: InputDecoration(
                  labelText: l10n.carPlateNumbersLabel,
                  border: const OutlineInputBorder(),
                ),
                validator: (_) => DriverValidators.carPlate(
                  letters: lettersController.text,
                  numbers: numbersController.text,
                  l10n: l10n,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PlateLettersFormatter extends TextInputFormatter {
  const _PlateLettersFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = EgyptianCarPlate.lettersField(newValue.text);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _PlateNumbersFormatter extends TextInputFormatter {
  const _PlateNumbersFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = EgyptianCarPlate.numbersField(newValue.text);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
