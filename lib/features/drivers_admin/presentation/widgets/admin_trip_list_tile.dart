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
import 'package:teletech_drivers/features/trip/presentation/widgets/trip_live_progress.dart';
import 'package:teletech_drivers/features/trip/presentation/widgets/trip_status_chip.dart';
import 'package:teletech_drivers/features/trip_request/presentation/utils/request_tracking_labels.dart';

/// Summary card for one trip on the drivers-admin trips list.
class AdminTripListTile extends ConsumerWidget {
  const AdminTripListTile({
    required this.trip,
    required this.onTap,
    this.showLiveProgress = false,
    this.animateIndex,
    this.enableHero = false,
    super.key,
  });

  /// Fly this card into the details header when opened.
  final bool enableHero;

  final Trip trip;
  final VoidCallback onTap;
  final bool showLiveProgress;
  final int? animateIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context);
    final languageCode = locale.languageCode;
    final dateFormat = DateFormat.yMMMd(locale.toString()).add_jm();
    final resolver = ref.watch(placeNameResolverProvider);
    final pickup = resolver.resolveSummary(
      summary: trip.pickupSummary,
      languageCode: languageCode,
    );
    final destination = resolver.resolveSummary(
      summary: trip.destinationSummary,
      languageCode: languageCode,
    );
    final routeSummary = l10n.tripRouteSummary(pickup, destination);
    final tracking = trip.tracking;
    final statusLabel = tracking == null
        ? tripStageLabel(trip, l10n)
        : trackingChipLabel(tracking.stage, l10n);
    final statusColor = tracking == null
        ? StatusChip.colorForTrip(trip.status)
        : trackingChipColor(tracking.stage);

    return TripCard(
      animateIndex: animateIndex,
      onTap: onTap,
      heroTripId: enableHero ? trip.id : null,
      title: routeSummary,
      from: pickup,
      to: destination,
      live: trip.status.isInProgress,
      statusLabel: statusLabel,
      statusColor: statusColor,
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (trip.branches.isNotEmpty) BranchChips(branches: trip.branches),
          if (trip.branches.isNotEmpty) const SizedBox(height: 8),
          Text(
            l10n.tripScheduledValue(
              dateFormat.format(trip.scheduledAt.toLocal()),
            ),
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            l10n.tripPassengersCount(trip.passengerNames.length),
            style: textTheme.bodySmall,
          ),
          TripConfirmationSummary(trip: trip),
          if (showLiveProgress) TripLiveProgress(trip: trip),
        ],
      ),
    );
  }
}
