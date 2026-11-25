import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Themed text field used across auth and forms.
class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.controller,
    required this.label,
    required this.textInputAction,
    this.keyboardType,
    this.autofillHints,
    this.obscureText = false,
    this.autocorrect = true,
    this.enabled = true,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.prefixIcon,
    this.suffix,
    this.minLines,
    this.maxLines = 1,
    this.maxLength,
    this.hintText,
    this.helperText,
    this.textCapitalization = TextCapitalization.none,
    super.key,
  });

  final TextEditingController controller;
  final String label;
  final TextInputAction textInputAction;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final bool obscureText;
  final bool autocorrect;
  final bool enabled;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final IconData? prefixIcon;
  final Widget? suffix;
  final int? minLines;
  final int? maxLines;
  final int? maxLength;
  final String? hintText;
  final String? helperText;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    final effectiveMaxLines = obscureText ? 1 : maxLines;
    final effectiveMinLines = obscureText ? 1 : minLines;
    final multiline = (effectiveMaxLines ?? 1) > 1;
    return TextFormField(
      controller: controller,
      enabled: enabled,
      obscureText: obscureText,
      autocorrect: autocorrect,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      textCapitalization: textCapitalization,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      minLines: effectiveMinLines,
      maxLines: effectiveMaxLines,
      maxLength: maxLength,
      onTap: () {
        SystemChannels.textInput.invokeMethod<void>('TextInput.show');
      },
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        helperText: helperText,
        alignLabelWithHint: multiline,
        // Tall fields keep the label on top so the hint shows straight away,
        // and the icon sits with the first line, not in the middle.
        floatingLabelBehavior: multiline ? FloatingLabelBehavior.always : null,
        prefixIcon: prefixIcon == null
            ? null
            : multiline
            ? Align(
                alignment: Alignment.topCenter,
                widthFactor: 1,
                heightFactor: 1,
                child: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Icon(prefixIcon),
                ),
              )
            : Icon(prefixIcon),
        suffixIcon: suffix,
      ),
    );
  }
}
