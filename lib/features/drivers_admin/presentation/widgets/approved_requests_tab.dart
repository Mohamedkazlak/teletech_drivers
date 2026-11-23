import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/presentation/highlighted_request.dart';
import 'package:teletech_drivers/core/presentation/glass_bar_inset.dart';
import 'package:teletech_drivers/core/presentation/app_loading_indicator.dart';
import 'package:teletech_drivers/core/presentation/branch_filter_bar.dart';
import 'package:teletech_drivers/core/router/app_routes.dart';
import 'package:teletech_drivers/core/utils/failure_messages.dart';
import 'package:teletech_drivers/features/auth/domain/entities/branch.dart';
import 'package:teletech_drivers/features/drivers_admin/presentation/controllers/approved_request_selection_controller.dart';
import 'package:teletech_drivers/features/drivers_admin/presentation/controllers/create_trips_controller.dart';
import 'package:teletech_drivers/features/drivers_admin/presentation/controllers/trip_assignment_controller.dart';
import 'package:teletech_drivers/features/drivers_admin/presentation/widgets/approved_request_tile.dart';
import 'package:teletech_drivers/features/drivers_admin/presentation/widgets/create_trips_action_bar.dart';
import 'package:teletech_drivers/features/drivers_admin/presentation/widgets/driver_picker_sheet.dart';
import 'package:teletech_drivers/features/drivers_admin/presentation/widgets/suggested_group_card.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip.dart';
import 'package:teletech_drivers/features/trip/presentation/providers/trip_providers.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/group_suggestion.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request_list_query.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request_stage.dart';
import 'package:teletech_drivers/features/trip_request/presentation/providers/trip_request_providers.dart';
import 'package:teletech_drivers/features/trip_request/presentation/scheduling/schedule_field_message.dart';
import 'package:teletech_drivers/features/trip_request/presentation/widgets/future_schedule_dialog.dart';

/// Drivers admin: approved requests awaiting a trip + same-day join suggestions.
class ApprovedRequestsTab extends ConsumerStatefulWidget {
  const ApprovedRequestsTab({super.key});

  @override
  ConsumerState<ApprovedRequestsTab> createState() =>
      _ApprovedRequestsTabState();
}

class _ApprovedRequestsTabState extends ConsumerState<ApprovedRequestsTab> {
  Branch? _branchFilter;
  TripRequestStage _stage = TripRequestStage.needsDriver;

  /// Group ids (suggestedGroupId or server clusterId) split this
  /// session so the admin can handle members as individuals.
  final Set<String> _splitGroupIds = {};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final query = TripRequestListQuery(stage: _stage, branch: _branchFilter);
    final approved = ref.watch(adminTripRequestsProvider(query));
    // Optional hint: while loading or on error no suggested groups are shown.
    final suggestions =
        ref
            .watch(approvedGroupingSuggestionsProvider(_branchFilter))
            .asData
            ?.value ??
        const <GroupSuggestion>[];
    final selectedIds = ref.watch(approvedRequestSelectionProvider);
    final createState = ref.watch(createTripsControllerProvider);

    ref.listen(
      adminTripRequestsProvider(
        TripRequestListQuery(
          stage: TripRequestStage.needsDriver,
          branch: _branchFilter,
        ),
      ),
      (_, next) {
        next.whenData((requests) {
          ref
              .read(approvedRequestSelectionProvider.notifier)
              .retainOnly(requests.map((item) => item.id));
        });
      },
    );

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 0),
          child: Row(
            children: [
              FilterChip(
                label: Text(l10n.filterPending),
                selected: _stage == TripRequestStage.needsDriver,
                onSelected: (_) =>
                    setState(() => _stage = TripRequestStage.needsDriver),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: Text(l10n.filterApproved),
                selected: _stage == TripRequestStage.assigned,
                onSelected: (_) =>
                    setState(() => _stage = TripRequestStage.assigned),
              ),
            ],
          ),
        ),
        BranchFilterBar(
          selected: _branchFilter,
          onChanged: (branch) => setState(() => _branchFilter = branch),
        ),
        Expanded(
          child: approved.when(
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
              if (_stage == TripRequestStage.assigned) {
                return _assignedList(context, l10n, filtered);
              }

              if (filtered.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.approvedRequestsEmptyTitle,
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.approvedRequestsEmptyMessage,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              final joinGroups = _buildJoinGroups(filtered, suggestions);
              final groupedIds = {
                for (final group in joinGroups)
                  for (final request in group.requests) request.id,
              };
              final individual = [
                for (final request in filtered)
                  if (!groupedIds.contains(request.id)) request,
              ];

              final selectedRequests = [
                for (final request in filtered)
                  if (selectedIds.contains(request.id)) request,
              ];

              return Column(
                children: [
                  Expanded(
                    child: ListView.separated(
                      padding: GlassBarInset.listPadding(
                        context,
                        const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 16),
                      ),
                      itemCount:
                          individual.length + (joinGroups.isEmpty ? 0 : 1),
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        if (joinGroups.isNotEmpty && index == 0) {
                          return Column(
                            children: [
                              for (
                                var groupIndex = 0;
                                groupIndex < joinGroups.length;
                                groupIndex++
                              ) ...[
                                HighlightedRequest(
                                  highlighted: joinGroups[groupIndex].requests
                                      .any(
                                        (item) =>
                                            item.id ==
                                            highlightedRequestId(context),
                                      ),
                                  child: SuggestedGroupCard(
                                  key: ValueKey(joinGroups[groupIndex].id),
                                  requests: joinGroups[groupIndex].requests,
                                  isLoading: createState.isLoading,
                                  onCreateGroupedTrip: () => _groupIntoOneTrip(
                                    joinGroups[groupIndex].requests,
                                  ),
                                  onSplit: () {
                                    final group = joinGroups[groupIndex];
                                    setState(
                                      () => _splitGroupIds.add(group.id),
                                    );
                                    ref
                                        .read(
                                          approvedRequestSelectionProvider
                                              .notifier,
                                        )
                                        .deselectAll(
                                          group.requests.map((item) => item.id),
                                        );
                                  },
                                  ),
                                ),
                                if (groupIndex < joinGroups.length - 1)
                                  const SizedBox(height: 12),
                              ],
                            ],
                          );
                        }
                        final itemIndex = joinGroups.isEmpty
                            ? index
                            : index - 1;
                        final request = individual[itemIndex];
                        final highlight = highlightedRequestId(context);
                        return HighlightedRequest(
                          highlighted: highlight == request.id,
                          child: ApprovedRequestTile(
                            request: request,
                            animateIndex: itemIndex,
                            selected: selectedIds.contains(request.id),
                            onSelectedChanged: (_) {
                              ref
                                  .read(
                                    approvedRequestSelectionProvider.notifier,
                                  )
                                  .toggle(request.id);
                            },
                            onTap: () => _assignFromCard(request),
                          ),
                        );
                      },
                    ),
                  ),
                  if (selectedRequests.isNotEmpty)
                    CreateTripsActionBar(
                      selectedCount: selectedRequests.length,
                      isLoading: createState.isLoading,
                      onCreateOnePerRequest: () =>
                          _createOnePerRequest(selectedRequests),
                      onGroupIntoOneTrip: () =>
                          _groupIntoOneTrip(selectedRequests),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  /// Company-admin [suggestedGroupId] groups first, then server-suggested
  /// clusters limited to the requests no admin group has claimed.
  List<_JoinGroup> _buildJoinGroups(
    List<TripRequest> requests,
    List<GroupSuggestion> suggestions,
  ) {
    final bySuggestedId = <String, List<TripRequest>>{};
    for (final request in requests) {
      final groupId = request.suggestedGroupId;
      if (groupId == null || _splitGroupIds.contains(groupId)) continue;
      (bySuggestedId[groupId] ??= []).add(request);
    }
    bySuggestedId.removeWhere((_, members) => members.length < 2);

    final groups = <_JoinGroup>[];
    final claimedIds = <String>{};
    for (final entry in bySuggestedId.entries) {
      final members = List<TripRequest>.from(entry.value)
        ..sort((a, b) => a.requestedDateTime.compareTo(b.requestedDateTime));
      groups.add(_JoinGroup(id: entry.key, requests: members));
      claimedIds.addAll(members.map((item) => item.id));
    }

    for (final suggestion in suggestions) {
      if (_splitGroupIds.contains(suggestion.clusterId)) continue;
      final members = [
        for (final request in suggestion.requests)
          if (!claimedIds.contains(request.id)) request,
      ];
      if (members.length < 2) continue;
      groups.add(_JoinGroup(id: suggestion.clusterId, requests: members));
    }

    groups.sort(
      (a, b) => a.requests.first.requestedDateTime.compareTo(
        b.requests.first.requestedDateTime,
      ),
    );
    return groups;
  }

  Future<void> _assignFromCard(TripRequest request) async {
    final trips = await ref
        .read(createTripsControllerProvider.notifier)
        .create(
          requests: [request],
          strategy: ref.read(oneRequestPerTripStrategyProvider),
        );
    if (!mounted) return;
    await _afterCreate(trips, assignWhenSingle: true);
  }

  Future<void> _createOnePerRequest(List<TripRequest> requests) async {
    final trips = await ref
        .read(createTripsControllerProvider.notifier)
        .create(
          requests: requests,
          strategy: ref.read(oneRequestPerTripStrategyProvider),
        );
    if (!mounted) return;
    await _afterCreate(trips, assignWhenSingle: requests.length == 1);
  }

  Future<void> _groupIntoOneTrip(List<TripRequest> requests) async {
    final l10n = AppLocalizations.of(context);
    DateTime? scheduledAt;
    String? fieldError;
    while (mounted) {
      scheduledAt = await FutureScheduleDialog.pick(
        context,
        initialUtc: scheduledAt,
        errorText: fieldError,
      );
      if (scheduledAt == null || !mounted) return;

      final trips = await ref
          .read(createTripsControllerProvider.notifier)
          .create(
            requests: requests,
            strategy: ref.read(groupedRequestsStrategyProvider),
            scheduledAt: scheduledAt,
          );
      if (!mounted) return;
      if (trips != null) {
        await _afterCreate(trips, assignWhenSingle: true);
        return;
      }
      final failure = ref.read(createTripsControllerProvider).failure;
      final message = scheduleFieldMessage(failure);
      if (message == null) {
        if (failure != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(failure.message(l10n))));
        }
        return;
      }
      fieldError = message;
    }
  }

  Future<void> _afterCreate(
    List<Trip>? trips, {
    required bool assignWhenSingle,
  }) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    if (trips == null) {
      final failure = ref.read(createTripsControllerProvider).failure;
      if (failure != null) {
        messenger.showSnackBar(SnackBar(content: Text(failure.message(l10n))));
      }
      return;
    }
    messenger.showSnackBar(SnackBar(content: Text(l10n.tripsCreated)));
    if (assignWhenSingle && trips.length == 1) {
      await _assignDriver(trips.first);
    }
  }

  Future<void> _assignDriver(Trip trip) async {
    final selected = await DriverPickerSheet.show(context, trip: trip);
    if (selected == null || !mounted) return;
    final succeeded = await ref
        .read(tripAssignmentControllerProvider.notifier)
        .assign(tripId: trip.id, driverId: selected.id);
    if (!mounted || !succeeded) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).tripDriverAssigned)),
    );
  }

  Widget _assignedList(
    BuildContext context,
    AppLocalizations l10n,
    List<TripRequest> requests,
  ) {
    if (requests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            l10n.approvedRequestsEmptyTitle,
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ListView.separated(
      padding: GlassBarInset.listPadding(
        context,
        const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 16),
      ),
      itemCount: requests.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final request = requests[index];
        return HighlightedRequest(
          highlighted: highlightedRequestId(context) == request.id,
          child: ApprovedRequestTile(
            request: request,
            animateIndex: index,
            selected: false,
            selectable: false,
            onSelectedChanged: (_) {},
            onTap: () {
              final tripId = request.tripId;
              if (tripId == null) return;
              context.push(AppRoutes.driversAdminTripDetailsPath(tripId));
            },
          ),
        );
      },
    );
  }

}

/// Display model for a joinable approved-request cluster.
class _JoinGroup {
  const _JoinGroup({required this.id, required this.requests});

  final String id;
  final List<TripRequest> requests;
}
