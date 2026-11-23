import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request.dart';

/// Suggested join group: same destination on the same day (or company-admin
/// [suggestedGroupId]).
class SuggestedGroupCard extends StatelessWidget {
  const SuggestedGroupCard({
    required this.requests,
    required this.isLoading,
    required this.onCreateGroupedTrip,
    required this.onSplit,
    super.key,
  });

  final List<TripRequest> requests;
  final bool isLoading;
  final VoidCallback onCreateGroupedTrip;
  final VoidCallback onSplit;

  static String routeLabelFor(List<TripRequest> members) {
    final destination = members.first.destinationPlaceName;
    final pickups = {for (final member in members) member.pickupPlaceName};
    if (pickups.length == 1) {
      return '${pickups.single} → $destination';
    }
    return destination;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context);
    final dateFormat = DateFormat.yMMMd(locale.toString()).add_jm();
    final routeLabel = routeLabelFor(requests);
    final employeeNames = requests.map((item) => item.employeeName).join(', ');

    return Card(
      elevation: 0,
      color: scheme.primaryContainer.withValues(alpha: 0.45),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.group_outlined, color: scheme.onPrimaryContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.suggestedGroupTitle(requests.length),
                    style: textTheme.titleMedium?.copyWith(
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(routeLabel, style: textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(
              l10n.suggestedGroupEmployees(employeeNames),
              style: textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            for (final request in requests)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '${request.employeeName} · '
                  '${dateFormat.format(request.requestedDateTime.toLocal())}',
                  style: textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: 12),
            if (isLoading)
              const LinearProgressIndicator()
            else ...[
              FilledButton(
                onPressed: onCreateGroupedTrip,
                child: Text(l10n.createGroupedTrip),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: onSplit,
                child: Text(l10n.splitSuggestedGroup),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
