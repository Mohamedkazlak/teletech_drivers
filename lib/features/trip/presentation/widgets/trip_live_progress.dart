import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/presentation/app_loading_indicator.dart';
import 'package:teletech_drivers/core/router/app_routes.dart';
import 'package:teletech_drivers/core/utils/failure_messages.dart';
import 'package:teletech_drivers/features/tracking/domain/entities/live_map_driver.dart';
import 'package:teletech_drivers/features/tracking/presentation/providers/tracking_providers.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip.dart';
import 'package:teletech_drivers/features/trip/presentation/widgets/trip_status_chip.dart';

/// Live status for an in-progress trip. Polls only while this widget is visible.
class TripLiveProgress extends ConsumerWidget {
  const TripLiveProgress({required this.trip, super.key});

  final Trip trip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driverId = trip.driverId;
    if (driverId == null || !TickerMode.valuesOf(context).enabled) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final locations = ref.watch(adminLiveMapLocationsProvider(driverId));

    return locations.when(
      loading: () => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: AppLoadingIndicator(label: l10n.loading),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(messageForError(error, l10n)),
      ),
      data: (items) {
        LiveMapDriver? match;
        for (final item in items) {
          if (item.driver.id == driverId) {
            match = item;
            break;
          }
        }
        final seen = match?.lastSeenAt;
        final locale = Localizations.localeOf(context).toString();
        final seenLabel = seen == null
            ? null
            : DateFormat.yMMMd(locale).add_jm().format(seen.toLocal());
        final status = match?.trip?.status ?? trip.status;

        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.tripStatusLine(status.label(l10n)),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (seenLabel != null)
                Text(
                  l10n.liveProgressLastSeen(seenLabel),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              TextButton(
                onPressed: () => context.push(
                  AppRoutes.driversAdminLiveMapPath(driverId: driverId),
                ),
                child: Text(l10n.openLiveMap),
              ),
            ],
          ),
        );
      },
    );
  }
}
