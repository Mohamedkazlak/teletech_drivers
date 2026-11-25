import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/presentation/app_loading_indicator.dart';
import 'package:teletech_drivers/core/presentation/glass_bar_inset.dart';
import 'package:teletech_drivers/core/router/app_routes.dart';
import 'package:teletech_drivers/core/utils/failure_messages.dart';
import 'package:teletech_drivers/core/widgets/empty_state.dart';
import 'package:teletech_drivers/features/drivers_admin/presentation/widgets/admin_trip_list_tile.dart';
import 'package:teletech_drivers/features/trip/domain/entities/created_trip_bucket.dart';
import 'package:teletech_drivers/features/trip/presentation/controllers/created_by_me_trips_controller.dart';

/// Drivers admin My Trips. Loads GET /my-trips (trips this user requested).
class CreatedByMeTripsPanel extends StatelessWidget {
  const CreatedByMeTripsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: l10n.myTripsTabActive),
              Tab(text: l10n.myTripsTabCompleted),
              Tab(text: l10n.myTripsTabCancelled),
            ],
          ),
          const Expanded(
            child: TabBarView(
              children: [
                _CreatedByMeList(bucket: CreatedTripBucket.active),
                _CreatedByMeList(bucket: CreatedTripBucket.completed),
                _CreatedByMeList(bucket: CreatedTripBucket.cancelled),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CreatedByMeList extends ConsumerWidget {
  const _CreatedByMeList({required this.bucket});

  final CreatedTripBucket bucket;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final page = ref.watch(createdByMeTripsProvider(bucket));

    return page.when(
      skipLoadingOnReload: true,
      loading: () => TripListSkeleton(label: l10n.loading),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(messageForError(error, l10n), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () =>
                    ref.invalidate(createdByMeTripsProvider(bucket)),
                child: Text(l10n.tryAgain),
              ),
            ],
          ),
        ),
      ),
      data: (list) {
        if (list.trips.isEmpty) {
          return EmptyState(
            icon: Icons.route_outlined,
            title: l10n.createdByMeEmptyTitle,
            message: l10n.createdByMeEmptyMessage,
          );
        }
        return ListView.separated(
          padding: GlassBarInset.listPadding(
            context,
            const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 88),
          ),
          itemCount: list.trips.length + (list.hasMore ? 1 : 0),
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (index >= list.trips.length) {
              return Align(
                child: TextButton(
                  onPressed: list.loadingMore
                      ? null
                      : () => ref
                            .read(createdByMeTripsProvider(bucket).notifier)
                            .loadMore(),
                  child: Text(l10n.loadMore),
                ),
              );
            }
            final trip = list.trips[index];
            return AdminTripListTile(
              trip: trip,
              animateIndex: index,
              onTap: () =>
                  context.push(AppRoutes.driversAdminTripDetailsPath(trip.id)),
            );
          },
        );
      },
    );
  }
}
