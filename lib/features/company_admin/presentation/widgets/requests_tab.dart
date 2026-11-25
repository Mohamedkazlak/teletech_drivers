import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/presentation/glass_bar_inset.dart';
import 'package:teletech_drivers/core/presentation/highlighted_request.dart';
import 'package:teletech_drivers/core/presentation/app_loading_indicator.dart';
import 'package:teletech_drivers/core/presentation/branch_filter_bar.dart';
import 'package:teletech_drivers/core/router/app_routes.dart';
import 'package:teletech_drivers/core/utils/failure_messages.dart';
import 'package:teletech_drivers/features/auth/domain/entities/branch.dart';
import 'package:teletech_drivers/features/company_admin/presentation/controllers/approve_trip_request_controller.dart';
import 'package:teletech_drivers/features/company_admin/presentation/controllers/reject_trip_request_controller.dart';
import 'package:teletech_drivers/features/company_admin/presentation/widgets/admin_request_tile.dart';
import 'package:teletech_drivers/features/company_admin/presentation/widgets/grouping_suggestion_banner.dart';
import 'package:teletech_drivers/features/company_admin/presentation/widgets/grouping_suggestions_sheet.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/group_suggestion.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request_list_query.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request_status.dart';
import 'package:teletech_drivers/features/trip_request/presentation/providers/trip_request_providers.dart';

/// Company admin: pending / approved / rejected with approve & reject actions.
class RequestsTab extends ConsumerStatefulWidget {
  const RequestsTab({super.key});

  @override
  ConsumerState<RequestsTab> createState() => _RequestsTabState();
}

class _RequestsTabState extends ConsumerState<RequestsTab> {
  TripRequestStatus _statusFilter = TripRequestStatus.pending;
  Branch? _branchFilter;
  bool _groupingBannerDismissed = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final requestsAsync = ref.watch(
      adminTripRequestsProvider(
        TripRequestListQuery(status: _statusFilter, branch: _branchFilter),
      ),
    );
    final approveState = ref.watch(approveTripRequestControllerProvider);
    final rejectState = ref.watch(rejectTripRequestControllerProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 0),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              l10n.approvalFilterLabel,
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
                label: Text(l10n.filterPending),
                selected: _statusFilter == TripRequestStatus.pending,
                onSelected: (_) =>
                    setState(() => _statusFilter = TripRequestStatus.pending),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: Text(l10n.filterApproved),
                selected: _statusFilter == TripRequestStatus.approved,
                onSelected: (_) =>
                    setState(() => _statusFilter = TripRequestStatus.approved),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: Text(l10n.filterRejected),
                selected: _statusFilter == TripRequestStatus.rejected,
                onSelected: (_) =>
                    setState(() => _statusFilter = TripRequestStatus.rejected),
              ),
            ],
          ),
        ),
        BranchFilterBar(
          selected: _branchFilter,
          onChanged: (branch) => setState(() => _branchFilter = branch),
        ),
        Expanded(
          child: requestsAsync.when(
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
            data: (filtered) {
              final suggestions = _statusFilter == TripRequestStatus.pending
                  ? _pendingSuggestions()
                  : const <GroupSuggestion>[];
              final groupableCount = [
                for (final suggestion in suggestions) ...suggestion.requests,
              ].map((item) => item.id).toSet().length;
              final showBanner =
                  !_groupingBannerDismissed &&
                  _statusFilter == TripRequestStatus.pending &&
                  suggestions.isNotEmpty;

              if (filtered.isEmpty && !showBanner) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.requestsEmptyTitle,
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.requestsEmptyMessage,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: GlassBarInset.listPadding(
                  context,
                  const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 16),
                ),
                itemCount: filtered.length + (showBanner ? 1 : 0),
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (showBanner && index == 0) {
                    return GroupingSuggestionBanner(
                      requestCount: groupableCount,
                      onTap: () => showGroupingSuggestionsSheet(
                        context: context,
                        suggestions: suggestions,
                      ),
                      onDismiss: () {
                        setState(() => _groupingBannerDismissed = true);
                      },
                    );
                  }
                  final itemIndex = showBanner ? index - 1 : index;
                  final request = filtered[itemIndex];
                  return HighlightedRequest(
                    highlighted: highlightedRequestId(context) == request.id,
                    child: AdminRequestTile(
                      request: request,
                      animateIndex: itemIndex,
                      isApproving:
                          approveState.activeRequestId == request.id &&
                          approveState.isLoading,
                      isRejecting:
                          rejectState.activeRequestId == request.id &&
                          rejectState.isLoading,
                      onTap: () {
                        context.push(
                          AppRoutes.companyAdminRequestDetailsPath(request.id),
                        );
                      },
                      onApprove: () => _approve(request),
                      onReject: () => _reject(request),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  /// Optional hint: while loading or on error the banner is simply hidden.
  List<GroupSuggestion> _pendingSuggestions() {
    final suggestions = ref.watch(
      pendingGroupingSuggestionsProvider(_branchFilter),
    );
    return suggestions.asData?.value ?? const <GroupSuggestion>[];
  }

  Future<void> _approve(TripRequest request) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.approveTripRequestTitle),
          content: Text(l10n.approveTripRequestMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.dialogCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.confirmApproveTripRequest),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;

    final succeeded = await ref
        .read(approveTripRequestControllerProvider.notifier)
        .approve(requestId: request.id);

    if (!mounted) return;
    final failure = ref.read(approveTripRequestControllerProvider).failure;
    final messenger = ScaffoldMessenger.of(context);
    if (succeeded) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.tripRequestApproved)));
    } else if (failure != null) {
      messenger.showSnackBar(SnackBar(content: Text(failure.message(l10n))));
    }
  }

  Future<void> _reject(TripRequest request) async {
    final l10n = AppLocalizations.of(context);
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        var canConfirm = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(l10n.rejectTripRequestTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.rejectTripRequestMessage),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reasonController,
                    maxLines: 3,
                    maxLength: 500,
                    onChanged: (value) {
                      final next = value.trim().isNotEmpty;
                      if (next == canConfirm) return;
                      setDialogState(() => canConfirm = next);
                    },
                    decoration: InputDecoration(
                      labelText: l10n.rejectionReasonLabel,
                      hintText: l10n.rejectionReasonHint,
                      errorText: canConfirm
                          ? null
                          : l10n.attendanceReasonRequired,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: Text(l10n.dialogCancel),
                ),
                FilledButton(
                  onPressed: canConfirm
                      ? () => Navigator.of(dialogContext).pop(true)
                      : null,
                  child: Text(l10n.confirmRejectTripRequest),
                ),
              ],
            );
          },
        );
      },
    );

    final reason = reasonController.text;
    reasonController.dispose();

    if (confirmed != true || !mounted) return;

    final succeeded = await ref
        .read(rejectTripRequestControllerProvider.notifier)
        .reject(requestId: request.id, reason: reason);

    if (!mounted) return;
    final failure = ref.read(rejectTripRequestControllerProvider).failure;
    final messenger = ScaffoldMessenger.of(context);
    if (succeeded) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.tripRequestRejected)));
    } else if (failure != null) {
      messenger.showSnackBar(SnackBar(content: Text(failure.message(l10n))));
    }
  }
}
