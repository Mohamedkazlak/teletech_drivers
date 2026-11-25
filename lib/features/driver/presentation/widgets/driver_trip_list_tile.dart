import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/presentation/branch_chip.dart';
import 'package:teletech_drivers/core/router/app_routes.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/core/theme/app_typography.dart';
import 'package:teletech_drivers/core/utils/failure_messages.dart';
import 'package:teletech_drivers/core/widgets/animated_error_banner.dart';
import 'package:teletech_drivers/core/widgets/app_button.dart';
import 'package:teletech_drivers/core/widgets/status_chip.dart';
import 'package:teletech_drivers/core/widgets/trip_card.dart';
import 'package:teletech_drivers/features/driver/presentation/controllers/driver_trip_lifecycle_controller.dart';
import 'package:teletech_drivers/features/place/presentation/providers/place_providers.dart';
import 'package:teletech_drivers/core/utils/measurement_format.dart';
import 'package:teletech_drivers/features/trip/domain/controllers/trip_phase_controller.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip.dart';
import 'package:teletech_drivers/features/trip/presentation/widgets/trip_requesters_section.dart';
import 'package:teletech_drivers/features/trip/presentation/widgets/trip_status_chip.dart';

/// Trip card for the driver home lists with phase actions by status.
class DriverTripListTile extends ConsumerWidget {
  const DriverTripListTile({
    required this.trip,
    this.animateIndex,
    this.showActions = true,
    this.showMetrics = false,
    super.key,
  });

  final Trip trip;
  final int? animateIndex;
  final bool showActions;
  final bool showMetrics;

  static const _phases = TripPhaseController();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final languageCode = locale.languageCode;
    final dateFormat = DateFormat.MMMd(locale.toString()).add_jm();
    final resolver = ref.watch(placeNameResolverProvider);
    final pickup = resolver.resolveSummary(
      summary: trip.pickupSummary,
      languageCode: languageCode,
    );
    final destination = resolver.resolveSummary(
      summary: trip.destinationSummary,
      languageCode: languageCode,
    );
    final routeSummary = l10n.tripRouteSummary(pickup, destination);
    final statusLabel = trip.status.label(l10n);
    final statusColor = StatusChip.colorForTrip(trip.status);
    final actionState = ref.watch(driverTripLifecycleControllerProvider);
    final isActive = actionState.activeTripId == trip.id;
    final action = showActions ? _phases.actionFor(trip.status) : null;
    final showLiveMap = showActions && trip.status.isInProgress;
    final distance = showMetrics
        ? formatKilometersFromMeters(trip.totalDistanceMeters)
        : null;
    final duration = showMetrics
        ? formatSpanHoursMinutes(trip.goingStartedAt, trip.finishedAt)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isActive && actionState.failure != null) ...[
          AnimatedErrorBanner(message: actionState.failure!.message(l10n)),
          const SizedBox(height: 8),
        ],
        TripCard(
          animateIndex: animateIndex,
          onTap: () => context.push(AppRoutes.driverTripDetailsPath(trip.id)),
          heroTripId: trip.id,
          title: routeSummary,
          from: pickup,
          to: destination,
          live: trip.status.isInProgress,
          meta: dateFormat.format(trip.scheduledAt.toLocal()),
          statusLabel: statusLabel,
          statusColor: statusColor,
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (trip.branches.isNotEmpty) ...[
                BranchChips(branches: trip.branches),
                const SizedBox(height: 10),
              ],
              TripRequestersSection(
                requesters: trip.requesters,
                passengerCount: trip.passengerCount,
              ),
              if (distance != null || duration != null) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    if (distance != null)
                      _Metric(
                        icon: Icons.straighten_rounded,
                        text: l10n.tripDistanceValue(distance),
                      ),
                    if (duration != null)
                      _Metric(
                        icon: Icons.schedule_rounded,
                        text: l10n.tripDurationValue(duration),
                      ),
                  ],
                ),
              ],
            ],
          ),
          footer: action != null || showLiveMap
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (showLiveMap) ...[
                      AppButton(
                        label: l10n.openLiveMap,
                        variant: AppButtonVariant.outlined,
                        onPressed: () =>
                            context.push(AppRoutes.driverLiveMapPath(trip.id)),
                      ),
                      if (action != null) const SizedBox(height: 8),
                    ],
                    if (action != null)
                      _TripPhaseActionButton(
                        trip: trip,
                        action: action,
                        isLoading: isActive && actionState.isLoading,
                      ),
                  ],
                )
              : null,
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.inkMuted),
        const SizedBox(width: 6),
        Text(
          text,
          style: AppTypography.tabular(
            Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.navy,
            ),
          ),
        ),
      ],
    );
  }
}

class _TripPhaseActionButton extends ConsumerWidget {
  const _TripPhaseActionButton({
    required this.trip,
    required this.action,
    required this.isLoading,
  });

  final Trip trip;
  final TripPhaseAction action;
  final bool isLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final label = switch (action) {
      TripPhaseAction.startTrip => l10n.startTrip,
      TripPhaseAction.arriveAtDestination => l10n.arrivedAtDestination,
      TripPhaseAction.startReturn => l10n.startReturn,
      TripPhaseAction.endTrip => l10n.endTrip,
    };

    return AppButton(
      label: label,
      variant: action == TripPhaseAction.endTrip
          ? AppButtonVariant.danger
          : AppButtonVariant.filled,
      isLoading: isLoading,
      loadingLabel: l10n.loading,
      onPressed: isLoading ? null : () => _confirm(context, ref),
    );
  }

  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final (title, message, confirmLabel, success) = switch (action) {
      TripPhaseAction.startTrip => (
        l10n.startTripConfirmTitle,
        l10n.startTripConfirmMessage,
        l10n.startTrip,
        l10n.tripStarted,
      ),
      TripPhaseAction.arriveAtDestination => (
        l10n.arrivedAtDestinationConfirmTitle,
        l10n.arrivedAtDestinationConfirmMessage,
        l10n.arrivedAtDestination,
        l10n.arrivedAtDestinationSuccess,
      ),
      TripPhaseAction.startReturn => (
        l10n.startReturnConfirmTitle,
        l10n.startReturnConfirmMessage,
        l10n.startReturn,
        l10n.startReturnSuccess,
      ),
      TripPhaseAction.endTrip => (
        l10n.endTripConfirmTitle,
        l10n.endTripConfirmMessage,
        l10n.endTrip,
        l10n.tripEnded,
      ),
    };

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.dialogCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(confirmLabel),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) return;

    final controller = ref.read(driverTripLifecycleControllerProvider.notifier);
    final ok = await switch (action) {
      TripPhaseAction.startTrip => controller.start(trip.id),
      TripPhaseAction.arriveAtDestination => controller.arriveAtDestination(
        trip.id,
      ),
      TripPhaseAction.startReturn => controller.startReturn(trip.id),
      TripPhaseAction.endTrip => controller.end(trip.id),
    };
    if (!context.mounted) return;
    if (!ok) {
      final failure = ref.read(driverTripLifecycleControllerProvider).failure;
      if (failure == null) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure.message(l10n))));
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(success)));
    if (action == TripPhaseAction.startTrip && context.mounted) {
      context.push(AppRoutes.driverLiveMapPath(trip.id));
    }
  }
}
