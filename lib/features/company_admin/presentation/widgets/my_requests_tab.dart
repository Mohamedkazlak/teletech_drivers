import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/presentation/glass_bar_inset.dart';
import 'package:teletech_drivers/core/presentation/app_loading_indicator.dart';
import 'package:teletech_drivers/core/utils/failure_messages.dart';
import 'package:teletech_drivers/core/widgets/empty_state.dart';
import 'package:teletech_drivers/features/company_admin/presentation/widgets/my_request_card.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip.dart';
import 'package:teletech_drivers/features/trip/presentation/providers/trip_providers.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/my_request_list_filter.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request.dart';
import 'package:teletech_drivers/features/trip_request/presentation/providers/trip_request_providers.dart';

/// Own trip requests with progress filters (company / drivers admin).
class MyRequestsTab extends ConsumerStatefulWidget {
  const MyRequestsTab({required this.requestDetailsPath, super.key});

  /// Builds the details route for a request id (role-specific path).
  final String Function(String requestId) requestDetailsPath;

  @override
  ConsumerState<MyRequestsTab> createState() => _MyRequestsTabState();
}

class _MyRequestsTabState extends ConsumerState<MyRequestsTab> {
  MyRequestListFilter _filter = MyRequestListFilter.all;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final requestsAsync = ref.watch(employeeTripRequestsProvider);
    final tripsAsync = ref.watch(allTripsProvider);

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 0),
          child: Row(
            children: [
              for (final entry in _filterEntries(l10n)) ...[
                if (entry.$1 != MyRequestListFilter.all)
                  const SizedBox(width: 8),
                FilterChip(
                  label: Text(entry.$2),
                  selected: _filter == entry.$1,
                  onSelected: (_) => setState(() => _filter = entry.$1),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: requestsAsync.when(
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
            data: (requests) {
              if (requests.isEmpty) {
                return EmptyState(
                  title: l10n.myRequestsEmptyTitle,
                  message: l10n.myRequestsEmptyMessage,
                  icon: Icons.assignment_outlined,
                );
              }

              return tripsAsync.when(
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
                data: (trips) => _buildList(
                  l10n: l10n,
                  requests: requests,
                  tripsById: {for (final trip in trips) trip.id: trip},
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  List<(MyRequestListFilter, String)> _filterEntries(AppLocalizations l10n) {
    return [
      (MyRequestListFilter.all, l10n.myRequestsFilterAll),
      (MyRequestListFilter.active, l10n.myRequestsFilterActive),
      (MyRequestListFilter.completed, l10n.myRequestsFilterCompleted),
      (
        MyRequestListFilter.cancelledRejected,
        l10n.myRequestsFilterCancelledRejected,
      ),
    ];
  }

  Widget _buildList({
    required AppLocalizations l10n,
    required List<TripRequest> requests,
    required Map<String, Trip> tripsById,
  }) {
    final filtered = [
      for (final request in requests)
        if (_filter.matches(
          request,
          request.tripId == null ? null : tripsById[request.tripId!],
        ))
          request,
    ];

    if (filtered.isEmpty) {
      return EmptyState(
        title: l10n.myRequestsEmptyTitle,
        message: l10n.myRequestsFilteredEmptyMessage,
        icon: Icons.filter_alt_outlined,
      );
    }

    return ListView.separated(
      padding: GlassBarInset.listPadding(
        context,
        const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 88),
      ),
      itemCount: filtered.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final request = filtered[index];
        final trip = request.tripId == null ? null : tripsById[request.tripId!];
        return MyRequestCard(
          request: request,
          trip: trip,
          animateIndex: index,
          onTap: () {
            context.push(widget.requestDetailsPath(request.id));
          },
        );
      },
    );
  }
}
