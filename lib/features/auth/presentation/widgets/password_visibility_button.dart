import 'package:flutter/material.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';

class PasswordVisibilityButton extends StatelessWidget {
  const PasswordVisibilityButton({
    required this.obscure,
    required this.onPressed,
    super.key,
  });

  final bool obscure;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return IconButton(
      tooltip: obscure ? l10n.showPassword : l10n.hidePassword,
      onPressed: onPressed,
      icon: Icon(
        obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
      ),
    );
  }
}
