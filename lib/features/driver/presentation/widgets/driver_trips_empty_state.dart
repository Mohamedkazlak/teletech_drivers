import 'package:flutter/material.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/widgets/empty_state.dart';

/// Empty state for a driver trips tab filter.
class DriverTripsEmptyState extends StatelessWidget {
  const DriverTripsEmptyState({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return EmptyState.route(
      title: l10n.driverTripsEmptyTitle,
      message: message,
    );
  }
}
