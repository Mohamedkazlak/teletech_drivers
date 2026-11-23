import 'package:flutter/material.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';

/// Bottom actions when approved requests are selected for trip creation.
class CreateTripsActionBar extends StatelessWidget {
  const CreateTripsActionBar({
    required this.selectedCount,
    required this.isLoading,
    required this.onCreateOnePerRequest,
    required this.onGroupIntoOneTrip,
    super.key,
  });

  final int selectedCount;
  final bool isLoading;
  final VoidCallback onCreateOnePerRequest;
  final VoidCallback onGroupIntoOneTrip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Material(
      elevation: 8,
      color: scheme.surfaceContainerHigh,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.selectedRequestsCount(selectedCount),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 10),
              if (isLoading)
                const LinearProgressIndicator()
              else ...[
                FilledButton(
                  onPressed: onCreateOnePerRequest,
                  child: Text(l10n.createOneTripPerRequest),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: onGroupIntoOneTrip,
                  child: Text(l10n.groupIntoOneTrip),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
