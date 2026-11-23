import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/presentation/branch_filter_bar.dart';
import 'package:teletech_drivers/features/auth/domain/entities/branch.dart';
import 'package:teletech_drivers/features/drivers_admin/presentation/widgets/admin_trips_list.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_list_query.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_stage.dart';
import 'package:teletech_drivers/features/trip/presentation/providers/trip_providers.dart';

/// Drivers admin trips filtered by server stage and branch.
class AdminTripsTab extends ConsumerStatefulWidget {
  const AdminTripsTab({super.key});

  @override
  ConsumerState<AdminTripsTab> createState() => _AdminTripsTabState();
}

class _AdminTripsTabState extends ConsumerState<AdminTripsTab> {
  Branch? _branchFilter;

  static const _stages = <TripStage>[
    TripStage.unassigned,
    TripStage.assigned,
    TripStage.inProgress,
    TripStage.completed,
    TripStage.awaitingReport,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return DefaultTabController(
      length: _stages.length,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: l10n.tripsUnassignedTab),
              Tab(text: l10n.tripsAssignedTab),
              Tab(text: l10n.tripsInProgressTab),
              Tab(text: l10n.tripsCompletedTab),
              Tab(text: l10n.tripsAwaitingReportTab),
            ],
          ),
          BranchFilterBar(
            selected: _branchFilter,
            onChanged: (branch) => setState(() => _branchFilter = branch),
          ),
          Expanded(
            child: TabBarView(
              children: [
                for (final stage in _stages)
                  AdminTripsList(
                    trips: ref.watch(
                      tripsQueryProvider(
                        TripListQuery(stage: stage, branch: _branchFilter),
                      ),
                    ),
                    emptyMessage: _emptyMessage(l10n, stage),
                    showLiveProgress: stage == TripStage.inProgress,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _emptyMessage(AppLocalizations l10n, TripStage stage) {
    return switch (stage) {
      TripStage.unassigned => l10n.adminTripsUnassignedEmptyMessage,
      TripStage.assigned => l10n.adminTripsAssignedEmptyMessage,
      TripStage.inProgress => l10n.adminTripsInProgressEmptyMessage,
      TripStage.completed => l10n.adminTripsCompletedEmptyMessage,
      TripStage.awaitingReport => l10n.adminTripsAwaitingReportEmptyMessage,
    };
  }
}
