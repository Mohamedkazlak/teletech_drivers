import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/presentation/glass_bar_inset.dart';
import 'package:teletech_drivers/core/presentation/app_loading_indicator.dart';
import 'package:teletech_drivers/core/router/app_routes.dart';
import 'package:teletech_drivers/core/utils/failure_messages.dart';
import 'package:teletech_drivers/features/drivers_admin/presentation/widgets/admin_trip_list_tile.dart';
import 'package:teletech_drivers/features/drivers_admin/presentation/widgets/admin_trips_empty_state.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip.dart';

/// Shared list body for drivers-admin trip filters.
class AdminTripsList extends ConsumerWidget {
  const AdminTripsList({
    required this.trips,
    required this.emptyMessage,
    this.showLiveProgress = false,
    super.key,
  });

  final AsyncValue<List<Trip>> trips;
  final String emptyMessage;
  final bool showLiveProgress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return trips.when(
      loading: () => TripListSkeleton(label: l10n.loading),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            messageForError(error, l10n),
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return AdminTripsEmptyState(message: emptyMessage);
        }
        return ListView.separated(
          padding: GlassBarInset.listPadding(
            context,
            const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 24),
          ),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final trip = items[index];
            return AdminTripListTile(
              trip: trip,
              animateIndex: index,
              enableHero: true,
              showLiveProgress: showLiveProgress,
              onTap: () {
                if (trip.status.isInProgress && trip.driverId != null) {
                  context.push(
                    AppRoutes.driversAdminLiveMapPath(driverId: trip.driverId),
                  );
                  return;
                }
                context.push(AppRoutes.driversAdminTripDetailsPath(trip.id));
              },
            );
          },
        );
      },
    );
  }
}
