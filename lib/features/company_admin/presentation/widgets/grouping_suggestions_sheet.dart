import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/utils/failure_messages.dart';
import 'package:teletech_drivers/features/company_admin/presentation/controllers/approve_trip_requests_as_group_controller.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/group_suggestion.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request.dart';

/// Bottom sheet listing suggested clusters; admin can trim, approve, or ignore.
Future<void> showGroupingSuggestionsSheet({
  required BuildContext context,
  required List<GroupSuggestion> suggestions,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (sheetContext) {
      return GroupingSuggestionsSheet(suggestions: suggestions);
    },
  );
}

class GroupingSuggestionsSheet extends ConsumerStatefulWidget {
  const GroupingSuggestionsSheet({required this.suggestions, super.key});

  final List<GroupSuggestion> suggestions;

  @override
  ConsumerState<GroupingSuggestionsSheet> createState() =>
      _GroupingSuggestionsSheetState();
}

class _GroupingSuggestionsSheetState
    extends ConsumerState<GroupingSuggestionsSheet> {
  /// Editable membership per cluster (admin can remove individuals).
  late final Map<String, List<TripRequest>> _membersByCluster;

  /// Clusters the admin chose to ignore in this sheet session.
  final Set<String> _ignoredClusterIds = {};

  @override
  void initState() {
    super.initState();
    _membersByCluster = {
      for (final suggestion in widget.suggestions)
        suggestion.clusterId: List<TripRequest>.from(suggestion.requests),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final dateFormat = DateFormat.yMMMd(locale.toString()).add_jm();
    final approveState = ref.watch(
      approveTripRequestsAsGroupControllerProvider,
    );
    final visible = [
      for (final suggestion in widget.suggestions)
        if (!_ignoredClusterIds.contains(suggestion.clusterId) &&
            (_membersByCluster[suggestion.clusterId]?.length ?? 0) >= 2)
          suggestion,
    ];

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 8),
              child: Text(
                l10n.groupingSuggestionsSheetTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            if (approveState.isLoading) const LinearProgressIndicator(),
            Expanded(
              child: visible.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          l10n.groupingSuggestionsEmpty,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        16,
                        8,
                        16,
                        24,
                      ),
                      itemCount: visible.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final suggestion = visible[index];
                        final members =
                            _membersByCluster[suggestion.clusterId]!;
                        return _ClusterCard(
                          suggestion: suggestion,
                          members: members,
                          dateFormat: dateFormat,
                          busy:
                              approveState.isLoading &&
                              approveState.activeRequestId ==
                                  suggestion.clusterId,
                          actionsDisabled: approveState.isLoading,
                          onRemove: (request) {
                            setState(() {
                              final next = List<TripRequest>.from(members)
                                ..removeWhere((item) => item.id == request.id);
                              _membersByCluster[suggestion.clusterId] = next;
                            });
                          },
                          onApprove: () => _approve(suggestion.clusterId),
                          onIgnore: () {
                            setState(() {
                              _ignoredClusterIds.add(suggestion.clusterId);
                            });
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _approve(String clusterId) async {
    final l10n = AppLocalizations.of(context);
    final members = _membersByCluster[clusterId];
    if (members == null || members.length < 2) return;

    final succeeded = await ref
        .read(approveTripRequestsAsGroupControllerProvider.notifier)
        .approveAsGroup(
          requestIds: members.map((item) => item.id).toList(),
          suggestedGroupId: clusterId,
        );

    if (!mounted) return;
    final failure = ref
        .read(approveTripRequestsAsGroupControllerProvider)
        .failure;
    final messenger = ScaffoldMessenger.of(context);
    if (succeeded) {
      setState(() {
        _ignoredClusterIds.add(clusterId);
        _membersByCluster.remove(clusterId);
      });
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.groupingSuggestionApproved)),
      );
      final remaining = widget.suggestions.where(
        (item) =>
            !_ignoredClusterIds.contains(item.clusterId) &&
            (_membersByCluster[item.clusterId]?.length ?? 0) >= 2,
      );
      if (remaining.isEmpty) {
        Navigator.of(context).pop();
      }
    } else if (failure != null) {
      messenger.showSnackBar(SnackBar(content: Text(failure.message(l10n))));
    }
  }
}

class _ClusterCard extends StatelessWidget {
  const _ClusterCard({
    required this.suggestion,
    required this.members,
    required this.dateFormat,
    required this.busy,
    required this.actionsDisabled,
    required this.onRemove,
    required this.onApprove,
    required this.onIgnore,
  });

  final GroupSuggestion suggestion;
  final List<TripRequest> members;
  final DateFormat dateFormat;
  final bool busy;
  final bool actionsDisabled;
  final ValueChanged<TripRequest> onRemove;
  final VoidCallback onApprove;
  final VoidCallback onIgnore;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final earliest = members
        .map((item) => item.requestedDateTime)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final latest = members
        .map((item) => item.requestedDateTime)
        .reduce((a, b) => a.isAfter(b) ? a : b);
    final timeSpan = earliest == latest
        ? dateFormat.format(earliest.toLocal())
        : '${dateFormat.format(earliest.toLocal())} – '
              '${dateFormat.format(latest.toLocal())}';

    return Card(
      elevation: 0,
      color: scheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(suggestion.routeLabel, style: textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              l10n.groupingSuggestionTimeSpan(timeSpan),
              style: textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              l10n.groupingSuggestionRequestCount(members.length),
              style: textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            for (final request in members)
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(request.employeeName),
                subtitle: Text(
                  dateFormat.format(request.requestedDateTime.toLocal()),
                ),
                trailing: IconButton(
                  tooltip: l10n.groupingSuggestionRemoveRequest,
                  onPressed: actionsDisabled ? null : () => onRemove(request),
                  icon: const Icon(Icons.remove_circle_outline),
                ),
              ),
            const SizedBox(height: 8),
            if (busy)
              const Center(child: CircularProgressIndicator())
            else ...[
              FilledButton(
                onPressed: actionsDisabled ? null : onApprove,
                child: Text(l10n.groupingSuggestionApproveAsGroup),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: actionsDisabled ? null : onIgnore,
                child: Text(l10n.groupingSuggestionIgnore),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
