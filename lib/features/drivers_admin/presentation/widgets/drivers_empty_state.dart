import 'package:flutter/material.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/widgets/app_button.dart';
import 'package:teletech_drivers/core/widgets/empty_state.dart';

/// Empty state when no drivers have been provisioned yet.
class DriversEmptyState extends StatelessWidget {
  const DriversEmptyState({required this.onAddDriver, super.key});

  final VoidCallback onAddDriver;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            EmptyState(
              icon: Icons.people_outline,
              title: l10n.driversEmptyTitle,
              message: l10n.driversEmptyMessage,
            ),
            const SizedBox(height: 8),
            AppButton(label: l10n.addDriver, onPressed: onAddDriver),
          ],
        ),
      ),
    );
  }
}
