import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/presentation/branch_chip.dart';
import 'package:teletech_drivers/core/widgets/status_chip.dart';
import 'package:teletech_drivers/core/widgets/trip_card.dart';
import 'package:teletech_drivers/features/place/presentation/providers/place_providers.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip.dart';
import 'package:teletech_drivers/features/trip/presentation/widgets/trip_confirmation_summary.dart';
import 'package:teletech_drivers/features/trip/presentation/widgets/trip_status_chip.dart';

/// Read-only trip summary for company admin: status, driver, times, branch.
class TripListTile extends ConsumerWidget {
  const TripListTile({
    required this.trip,
    required this.onTap,
    this.driverName,
    this.animateIndex,
    super.key,
  });

  final Trip trip;
  final VoidCallback onTap;
  final String? driverName;
  final int? animateIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context);
    final languageCode = locale.languageCode;
    final dateFormat = DateFormat.yMMMd(locale.toString()).add_jm();
    final statusLabel = tripStageLabel(trip, l10n);
    final statusColor = StatusChip.colorForTrip(trip.status);
    final resolver = ref.watch(placeNameResolverProvider);
    final pickupName = resolver.resolveSummary(
      summary: trip.pickupSummary,
      languageCode: languageCode,
    );
    final destinationName = resolver.resolveSummary(
      summary: trip.destinationSummary,
      languageCode: languageCode,
    );

    return TripCard(
      animateIndex: animateIndex,
      onTap: onTap,
      title: l10n.tripRouteSummary(pickupName, destinationName),
      from: pickupName,
      to: destinationName,
      statusLabel: statusLabel,
      statusColor: statusColor,
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (trip.branches.isNotEmpty) BranchChips(branches: trip.branches),
          if (trip.branches.isNotEmpty) const SizedBox(height: 8),
          Text(
            driverName == null || driverName!.isEmpty
                ? l10n.tripDriverUnassigned
                : l10n.tripDriverNameValue(driverName!),
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            l10n.tripScheduledValue(
              dateFormat.format(trip.scheduledAt.toLocal()),
            ),
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            trip.startedAt == null
                ? l10n.tripNotStartedYet
                : l10n.tripStartedValue(
                    dateFormat.format(trip.startedAt!.toLocal()),
                  ),
            style: textTheme.bodySmall,
          ),
          const SizedBox(height: 2),
          Text(
            trip.endedAt == null
                ? l10n.tripNotEndedYet
                : l10n.tripEndedValue(
                    dateFormat.format(trip.endedAt!.toLocal()),
                  ),
            style: textTheme.bodySmall,
          ),
          TripConfirmationSummary(trip: trip),
        ],
      ),
    );
  }
}
