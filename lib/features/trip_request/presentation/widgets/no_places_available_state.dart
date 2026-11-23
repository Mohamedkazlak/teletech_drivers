import 'package:flutter/material.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/widgets/empty_state.dart';

/// Empty state when the employee cannot request a trip yet (no places).
class NoPlacesAvailableState extends StatelessWidget {
  const NoPlacesAvailableState({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return EmptyState(
      icon: Icons.place_outlined,
      title: l10n.noPlacesForRequestTitle,
      message: l10n.noPlacesForRequestMessage,
    );
  }
}
