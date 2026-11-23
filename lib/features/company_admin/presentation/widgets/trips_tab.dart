import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/presentation/glass_bar_inset.dart';
import 'package:teletech_drivers/core/presentation/app_loading_indicator.dart';
import 'package:teletech_drivers/core/presentation/branch_filter_bar.dart';
import 'package:teletech_drivers/core/router/app_routes.dart';
import 'package:teletech_drivers/core/utils/failure_messages.dart';
import 'package:teletech_drivers/features/auth/domain/entities/branch.dart';
import 'package:teletech_drivers/features/company_admin/presentation/widgets/trip_list_tile.dart';
import 'package:teletech_drivers/features/company_admin/presentation/widgets/trips_empty_state.dart';
import 'package:teletech_drivers/features/drivers_admin/presentation/providers/driver_providers.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_lifecycle.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_list_query.dart';
import 'package:teletech_drivers/features/trip/presentation/providers/trip_providers.dart';

/// Company admin tab: read-only trips filtered by trip status, then branch.
class TripsTab extends ConsumerStatefulWidget {
  const TripsTab({super.key});

  @override
  ConsumerState<TripsTab> createState() => _TripsTabState();
}

class _TripsTabState extends ConsumerState<TripsTab> {
  TripLifecycle? _lifecycle;
  Branch? _branchFilter;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final trips = ref.watch(
      tripsQueryProvider(
        TripListQuery(lifecycle: _lifecycle, branch: _branchFilter),
      ),
    );
    final drivers = ref.watch(allDriversProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 0),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              l10n.tripStatusFilterLabel,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 0),
          child: Row(
            children: [
              FilterChip(
                label: Text(l10n.branchFilterAll),
                selected: _lifecycle == null,
                onSelected: (_) => setState(() => _lifecycle = null),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: Text(l10n.tripStatusUpcoming),
                selected: _lifecycle == TripLifecycle.upcoming,
                onSelected: (_) =>
                    setState(() => _lifecycle = TripLifecycle.upcoming),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: Text(l10n.tripStatusFilterInProgress),
                selected: _lifecycle == TripLifecycle.inProgress,
                onSelected: (_) =>
                    setState(() => _lifecycle = TripLifecycle.inProgress),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: Text(l10n.tripStatusCompleted),
                selected: _lifecycle == TripLifecycle.completed,
                onSelected: (_) =>
                    setState(() => _lifecycle = TripLifecycle.completed),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: Text(l10n.tripStatusCancelled),
                selected: _lifecycle == TripLifecycle.cancelled,
                onSelected: (_) =>
                    setState(() => _lifecycle = TripLifecycle.cancelled),
              ),
            ],
          ),
        ),
        BranchFilterBar(
          selected: _branchFilter,
          onChanged: (branch) => setState(() => _branchFilter = branch),
        ),
        Expanded(
          child: trips.when(
            loading: () =>
                Center(child: AppLoadingIndicator(label: l10n.loading)),
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
            data: (filtered) {
              if (filtered.isEmpty) {
                return const TripsEmptyState();
              }

              final languageCode = Localizations.localeOf(context).languageCode;
              final driverNames = <String, String>{};
              drivers.whenData((list) {
                for (final driver in list) {
                  driverNames[driver.id] = driver.localizedName(languageCode);
                }
              });

              return ListView.separated(
                padding: GlassBarInset.listPadding(
                  context,
                  const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 24),
                ),
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final trip = filtered[index];
                  final driverId = trip.driverId;
                  return TripListTile(
                    trip: trip,
                    animateIndex: index,
                    driverName: driverId == null ? null : driverNames[driverId],
                    onTap: () {
                      context.push(
                        AppRoutes.companyAdminTripDetailsPath(trip.id),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
