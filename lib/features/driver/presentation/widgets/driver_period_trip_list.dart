import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/presentation/app_loading_indicator.dart';
import 'package:teletech_drivers/core/presentation/glass_bar_inset.dart';
import 'package:teletech_drivers/core/utils/failure_messages.dart';
import 'package:teletech_drivers/core/widgets/list_failure_view.dart';
import 'package:teletech_drivers/features/driver/presentation/providers/driver_period_providers.dart';
import 'package:teletech_drivers/features/driver/presentation/widgets/driver_trip_list_tile.dart';
import 'package:teletech_drivers/features/driver/presentation/widgets/driver_trips_empty_state.dart';
import 'package:teletech_drivers/features/trip/domain/entities/mine_trips_filter.dart';

/// Period-scoped driver trip list with loading, empty, and error states.
class DriverPeriodTripList extends ConsumerWidget {
  const DriverPeriodTripList({
    required this.filter,
    required this.emptyMessage,
    this.showActions = true,
    this.showMetrics = false,
    super.key,
  });

  final MineTripsFilter filter;
  final String emptyMessage;
  final bool showActions;
  final bool showMetrics;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final trips = ref.watch(driverMineTripsProvider(filter));

    Future<void> refresh() async {
      ref.invalidate(driverMineTripsProvider(filter));
      try {
        await ref.read(driverMineTripsProvider(filter).future);
      } on Object {
        // The list shows the failure.
      }
    }

    return trips.when(
      loading: () => Align(
        alignment: AlignmentDirectional.topCenter,
        child: TripListSkeleton(label: l10n.loading),
      ),
      error: (error, _) => ListFailureView(
        message: messageForError(error, l10n),
        onRetry: () => ref.invalidate(driverMineTripsProvider(filter)),
      ),
      data: (items) {
        if (items.isEmpty) {
          return RefreshIndicator(
            onRefresh: refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: 420,
                  child: DriverTripsEmptyState(message: emptyMessage),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: refresh,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: GlassBarInset.listPadding(
              context,
              const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 24),
            ),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return DriverTripListTile(
                trip: items[index],
                animateIndex: index,
                showActions: showActions,
                showMetrics: showMetrics,
              );
            },
          ),
        );
      },
    );
  }
}
