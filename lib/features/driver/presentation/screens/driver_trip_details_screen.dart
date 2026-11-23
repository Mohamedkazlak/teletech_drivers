import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/presentation/app_loading_indicator.dart';
import 'package:teletech_drivers/core/presentation/branch_chip.dart';
import 'package:teletech_drivers/core/router/app_routes.dart';
import 'package:teletech_drivers/core/utils/failure_messages.dart';
import 'package:teletech_drivers/core/widgets/app_button.dart';
import 'package:teletech_drivers/core/widgets/app_scaffold.dart';
import 'package:teletech_drivers/features/place/presentation/providers/place_providers.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip.dart';
import 'package:teletech_drivers/features/trip/presentation/providers/trip_providers.dart';
import 'package:teletech_drivers/features/trip/presentation/widgets/trip_report_section.dart';
import 'package:teletech_drivers/features/trip/presentation/widgets/trip_requesters_section.dart';
import 'package:teletech_drivers/features/trip/presentation/widgets/trip_status_chip.dart';

/// Driver trip details with live trip report (own trips only).
class DriverTripDetailsScreen extends ConsumerWidget {
  const DriverTripDetailsScreen({required this.tripId, super.key});

  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tripAsync = ref.watch(watchTripByIdProvider(tripId));

    return AppScaffold(
      title: l10n.tripDetailsTitle,
      showBackButton: true,
      body: tripAsync.when(
        loading: () => Center(child: AppLoadingIndicator(label: l10n.loading)),
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
        data: (trip) {
          if (trip == null) {
            return Center(
              child: Text(
                l10n.errorNotFound,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            );
          }
          return _DriverTripDetailsBody(trip: trip);
        },
      ),
    );
  }
}

class _DriverTripDetailsBody extends ConsumerWidget {
  const _DriverTripDetailsBody({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context);
    final languageCode = locale.languageCode;
    final dateFormat = DateFormat.yMMMd(locale.toString()).add_jm();
    final resolver = ref.watch(placeNameResolverProvider);

    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.tripRouteSummary(
                  resolver.resolveSummary(
                    summary: trip.pickupSummary,
                    languageCode: languageCode,
                  ),
                  resolver.resolveSummary(
                    summary: trip.destinationSummary,
                    languageCode: languageCode,
                  ),
                ),
                style: textTheme.headlineSmall,
              ),
            ),
            TripStatusChip(status: trip.status),
          ],
        ),
        if (trip.branches.isNotEmpty) ...[
          const SizedBox(height: 8),
          BranchChips(branches: trip.branches),
        ],
        const SizedBox(height: 12),
        Text(
          l10n.tripScheduledValue(
            dateFormat.format(trip.scheduledAt.toLocal()),
          ),
          style: textTheme.bodyLarge,
        ),
        const SizedBox(height: 12),
        TripRequestersSection(
          requesters: trip.requesters,
          passengerCount: trip.passengerCount,
        ),
        if (trip.status.isInProgress) ...[
          const SizedBox(height: 12),
          AppButton(
            label: l10n.openLiveMap,
            variant: AppButtonVariant.outlined,
            onPressed: () {
              context.push(AppRoutes.driverLiveMapPath(trip.id));
            },
          ),
        ],
        if (TripReportSection.shouldShow(trip)) ...[
          const SizedBox(height: 20),
          TripReportSection(trip: trip),
        ],
      ],
    );
  }
}
