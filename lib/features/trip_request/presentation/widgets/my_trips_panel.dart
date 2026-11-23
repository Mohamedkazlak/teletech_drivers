import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/presentation/app_loading_indicator.dart';
import 'package:teletech_drivers/core/presentation/glass_bar_inset.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/core/utils/failure_messages.dart';
import 'package:teletech_drivers/core/widgets/empty_state.dart';
import 'package:teletech_drivers/core/widgets/list_failure_view.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request_list_bucket.dart';
import 'package:teletech_drivers/features/trip_request/presentation/controllers/cancel_trip_request_controller.dart';
import 'package:teletech_drivers/features/trip_request/presentation/providers/trip_request_providers.dart';
import 'package:teletech_drivers/features/trip_request/presentation/widgets/trip_request_card.dart';

/// My Trips: All / Active / Completed / Cancelled, plus the report banner.
class MyTripsPanel extends ConsumerWidget {
  const MyTripsPanel({
    required this.detailsPath,
    this.cancelledTabLabel,
    super.key,
  });

  final String Function(String requestId) detailsPath;

  /// Company admin uses "Cancelled/Rejected". Employees keep the default.
  final String? cancelledTabLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return DefaultTabController(
      length: _tabs.length,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _AwaitingReportBanner(),
          TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: l10n.myTripsTabAll),
              Tab(text: l10n.myTripsTabActive),
              Tab(text: l10n.myTripsTabCompleted),
              Tab(text: cancelledTabLabel ?? l10n.myTripsTabCancelled),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                for (final bucket in _tabs)
                  _MyTripsTab(bucket: bucket, detailsPath: detailsPath),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const _tabs = <TripRequestListBucket?>[
  null,
  TripRequestListBucket.active,
  TripRequestListBucket.completed,
  TripRequestListBucket.cancelled,
];

class _AwaitingReportBanner extends ConsumerWidget {
  const _AwaitingReportBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final awaiting = ref.watch(awaitingConfirmationProvider);

    return awaiting.when(
      loading: () => const SizedBox.shrink(),
      error: (error, _) => InlineFailureBanner(
        message: messageForError(error, l10n),
        onRetry: () => ref.invalidate(awaitingConfirmationProvider),
      ),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 4),
          child: Material(
            color: AppColors.warning.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(12, 12, 12, 12),
              child: Row(
                children: [
                  const Icon(Icons.fact_check_outlined, color: AppColors.navy),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.myTripsNeedReport(items.length),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MyTripsTab extends ConsumerWidget {
  const _MyTripsTab({required this.bucket, required this.detailsPath});

  final TripRequestListBucket? bucket;
  final String Function(String requestId) detailsPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final requests = ref.watch(myTripRequestsProvider(bucket));
    final cancelState = ref.watch(cancelTripRequestControllerProvider);

    Future<void> refresh() async {
      ref.invalidate(myTripRequestsProvider(bucket));
      ref.invalidate(awaitingConfirmationProvider);
      try {
        await ref.read(myTripRequestsProvider(bucket).future);
      } on Object {
        // The list shows the failure.
      }
    }

    return requests.when(
      loading: () => Center(child: AppLoadingIndicator(label: l10n.loading)),
      error: (error, _) => ListFailureView(
        message: messageForError(error, l10n),
        onRetry: () => ref.invalidate(myTripRequestsProvider(bucket)),
      ),
      data: (items) {
        if (items.isEmpty) {
          return RefreshIndicator(
            onRefresh: refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(
                  height: 360,
                  child: EmptyState(
                    icon: Icons.alt_route_outlined,
                    title: l10n.myTripsEmptyTitle,
                    message: l10n.myTripsEmptyMessage,
                  ),
                ),
              ],
            ),
          );
        }
        Widget cardAt(BuildContext context, int index) {
          final request = items[index];
          return TripRequestCard(
            request: request,
            animateIndex: index,
            isCancelling: cancelState.activeRequestId == request.id,
            onOpen: () => context.push(detailsPath(request.id)),
            onCancel: () => _confirmAndCancel(context, ref, request),
          );
        }

        return RefreshIndicator(
          onRefresh: refresh,
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: GlassBarInset.listPadding(
              context,
              const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 88),
            ),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: cardAt,
          ),
        );
      },
    );
  }

  Future<void> _confirmAndCancel(
    BuildContext context,
    WidgetRef ref,
    TripRequest request,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.cancelTripRequestConfirmTitle),
          content: Text(l10n.cancelTripRequestConfirmMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.dialogDismiss),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.confirmCancelTripRequest),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;

    final succeeded = await ref
        .read(cancelTripRequestControllerProvider.notifier)
        .cancel(request.id);

    if (!context.mounted) return;

    final failure = ref.read(cancelTripRequestControllerProvider).failure;
    final messenger = ScaffoldMessenger.of(context);
    if (succeeded) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.tripRequestCancelled)),
      );
    } else if (failure != null) {
      messenger.showSnackBar(SnackBar(content: Text(failure.message(l10n))));
    }
  }
}
