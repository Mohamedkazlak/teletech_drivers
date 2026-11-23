import 'package:flutter/material.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/widgets/empty_state.dart';

/// Empty state when the company has no trips yet.
class TripsEmptyState extends StatelessWidget {
  const TripsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return EmptyState(
      icon: Icons.route_outlined,
      title: l10n.tripsEmptyTitle,
      message: l10n.tripsEmptyMessage,
    );
  }
}
