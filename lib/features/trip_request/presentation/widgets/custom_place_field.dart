import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:teletech_drivers/features/trip_request/presentation/models/place_selection.dart';

/// Free-text field shown when the employee chooses a custom ("Other") place.
class CustomPlaceField extends StatelessWidget {
  const CustomPlaceField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.onChanged,
    this.errorText,
    this.enabled = true,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final String? errorText;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.sentences,
      maxLength: CustomPlaceSelection.maxNameLength,
      inputFormatters: [
        LengthLimitingTextInputFormatter(CustomPlaceSelection.maxNameLength),
      ],
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        errorText: errorText,
        counterText: '',
      ),
      onChanged: onChanged,
    );
  }
}
