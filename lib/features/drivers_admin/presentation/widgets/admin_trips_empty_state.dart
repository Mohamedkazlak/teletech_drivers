import 'package:flutter/material.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/widgets/empty_state.dart';

/// Empty state for a drivers-admin trips tab filter.
class AdminTripsEmptyState extends StatelessWidget {
  const AdminTripsEmptyState({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return EmptyState(
      icon: Icons.route_outlined,
      title: l10n.adminTripsEmptyTitle,
      message: message,
    );
  }
}
