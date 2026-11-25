import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/widgets/app_scaffold.dart';
import 'package:teletech_drivers/core/presentation/app_loading_indicator.dart';
import 'package:teletech_drivers/core/presentation/branch_chip.dart';
import 'package:teletech_drivers/core/presentation/requester_contact_section.dart';
import 'package:teletech_drivers/core/utils/failure_messages.dart';
import 'package:teletech_drivers/core/widgets/status_chip.dart';
import 'package:teletech_drivers/core/widgets/trip_hero.dart';
import 'package:teletech_drivers/features/auth/presentation/providers/auth_providers.dart';
import 'package:teletech_drivers/features/drivers_admin/presentation/providers/driver_providers.dart';
import 'package:teletech_drivers/features/place/presentation/providers/place_providers.dart';
import 'package:teletech_drivers/features/place/presentation/utils/place_coordinate_lookup.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip.dart';
import 'package:teletech_drivers/features/trip/presentation/providers/trip_providers.dart';
import 'package:teletech_drivers/features/trip/presentation/widgets/trip_confirmation_summary.dart';
import 'package:teletech_drivers/features/trip/presentation/widgets/trip_status_chip.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request.dart';
import 'package:teletech_drivers/features/trip_request/presentation/providers/trip_request_providers.dart';
import 'package:teletech_drivers/features/trip_request/presentation/widgets/own_trip_report_section.dart';
import 'package:teletech_drivers/features/trip_request/presentation/widgets/trip_place_line.dart';

/// Read-only trip progress for company admin (no assignment actions).
class TripDetailsScreen extends ConsumerWidget {
  const TripDetailsScreen({required this.tripId, super.key});

  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tripAsync = ref.watch(tripByIdProvider(tripId));

    return AppScaffold(
      title: l10n.tripDetailsTitle,
      showBackButton: true,
      body: tripAsync.when(
        loading: () => TripHeroPlaceholder(tripId: tripId),
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
          return _TripDetailsBody(trip: trip);
        },
      ),
    );
  }
}

class _TripDetailsBody extends ConsumerWidget {
  const _TripDetailsBody({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context);
    final languageCode = locale.languageCode;
    final dateFormat = DateFormat.yMMMd(locale.toString()).add_jm();
    final joinedIds = trip.requestIds.join(',');
    final requestsAsync = ref.watch(tripRequestsByIdsProvider(joinedIds));
    final drivers = ref.watch(allDriversProvider);
    final resolver = ref.watch(placeNameResolverProvider);
    final pickupName = resolver.resolveSummary(
      summary: trip.pickupSummary,
      languageCode: languageCode,
    );
    final destinationName = resolver.resolveSummary(
      summary: trip.destinationSummary,
      languageCode: languageCode,
    );
    final ownsReport =
        ownPendingReportRequestId(
          ref.watch(currentUserProvider).asData?.value,
          trip,
        ) !=
        null;
    final driverId = trip.driverId;
    String? driverName;
    drivers.whenData((list) {
      if (driverId == null) return;
      for (final driver in list) {
        if (driver.id == driverId) {
          driverName = driver.localizedName(languageCode);
          break;
        }
      }
    });

    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 24),
      children: [
        TripHero(
          tripId: trip.id,
          child: TripHeroHeader(
            from: pickupName,
            to: destinationName,
            statusLabel: tripStageLabel(trip, l10n),
            statusColor: StatusChip.colorForTrip(trip.status),
            live: trip.status.isInProgress,
            meta: dateFormat.format(trip.scheduledAt.toLocal()),
            footer: TripHeroInfoRow(
              icon: Icons.local_taxi_outlined,
              label: driverName == null
                  ? l10n.tripDriverUnassigned
                  : l10n.tripDriverNameValue(driverName!),
            ),
          ),
        ),
        if (trip.branches.isNotEmpty) ...[
          const SizedBox(height: 12),
          BranchChips(branches: trip.branches),
        ],
        if (!ownsReport) TripConfirmationSummary(trip: trip),
        OwnTripReportSection(trip: trip),
        const SizedBox(height: 16),
        Text(l10n.tripEventsSection, style: textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          trip.startedAt == null
              ? l10n.tripNotStartedYet
              : l10n.tripStartedValue(
                  dateFormat.format(trip.startedAt!.toLocal()),
                ),
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: 4),
        Text(
          trip.endedAt == null
              ? l10n.tripNotEndedYet
              : l10n.tripEndedValue(dateFormat.format(trip.endedAt!.toLocal())),
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        Text(l10n.tripRequestsSection, style: textTheme.titleMedium),
        const SizedBox(height: 8),
        requestsAsync.when(
          loading: () => AppLoadingIndicator(label: l10n.loading),
          error: (error, _) =>
              Text(messageForError(error, l10n), style: textTheme.bodyMedium),
          data: (requests) {
            if (requests.isEmpty) {
              return Text(l10n.homeEmpty, style: textTheme.bodyMedium);
            }
            return Column(
              children: [
                for (final request in requests)
                  _LinkedRequestCard(request: request, dateFormat: dateFormat),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _LinkedRequestCard extends ConsumerWidget {
  const _LinkedRequestCard({required this.request, required this.dateFormat});

  final TripRequest request;
  final DateFormat dateFormat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final languageCode = Localizations.localeOf(context).languageCode;
    final resolver = ref.watch(placeNameResolverProvider);
    final places = ref.watch(allPlacesProvider).asData?.value ?? const [];
    final pickupName = resolver.resolve(
      storedName: request.pickupPlaceName,
      languageCode: languageCode,
      placeId: request.pickupPlaceId,
    );
    final destinationName = resolver.resolve(
      storedName: request.destinationPlaceName,
      languageCode: languageCode,
      placeId: request.destinationPlaceId,
    );
    final pickupCoords = PlaceCoordinateLookup.resolve(
      requestLatitude: request.pickupLat,
      requestLongitude: request.pickupLng,
      placeId: request.pickupPlaceId,
      places: places,
    );
    final destinationCoords = PlaceCoordinateLookup.resolve(
      requestLatitude: request.destinationLat,
      requestLongitude: request.destinationLng,
      placeId: request.destinationPlaceId,
      places: places,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RequesterContactSection(
              name: request.employeeName,
              branch: request.employeeBranch,
              phone: request.employeePhone,
            ),
            const SizedBox(height: 10),
            TripPlaceLine(
              text: l10n.tripRequestPickupValue(pickupName),
              style: textTheme.bodyMedium,
              showCustomChip: request.hasCustomPickupLocation,
              address: request.pickupAddress,
              latitude: pickupCoords.latitude,
              longitude: pickupCoords.longitude,
              previewHeight: 96,
            ),
            const SizedBox(height: 2),
            TripPlaceLine(
              text: l10n.tripRequestDestinationValue(destinationName),
              style: textTheme.bodyMedium,
              showCustomChip: request.hasCustomDestinationLocation,
              address: request.destinationAddress,
              latitude: destinationCoords.latitude,
              longitude: destinationCoords.longitude,
              previewHeight: 96,
            ),
            const SizedBox(height: 2),
            Text(
              l10n.tripRequestWhenValue(
                dateFormat.format(request.requestedDateTime.toLocal()),
              ),
              style: textTheme.bodyMedium,
            ),
            if (request.notes.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                l10n.tripRequestNotesValue(request.notes),
                style: textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
