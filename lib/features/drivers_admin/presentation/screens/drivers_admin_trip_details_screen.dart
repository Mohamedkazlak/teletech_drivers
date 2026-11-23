import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/router/app_routes.dart';
import 'package:teletech_drivers/core/widgets/app_button.dart';
import 'package:teletech_drivers/core/widgets/app_scaffold.dart';
import 'package:teletech_drivers/core/presentation/app_loading_indicator.dart';
import 'package:teletech_drivers/core/presentation/branch_chip.dart';
import 'package:teletech_drivers/core/presentation/requester_contact_section.dart';
import 'package:teletech_drivers/core/utils/failure_messages.dart';
import 'package:teletech_drivers/core/widgets/status_chip.dart';
import 'package:teletech_drivers/features/auth/domain/entities/app_user.dart';
import 'package:teletech_drivers/features/auth/presentation/providers/auth_providers.dart';
import 'package:teletech_drivers/features/drivers_admin/presentation/controllers/trip_assignment_controller.dart';
import 'package:teletech_drivers/features/drivers_admin/presentation/providers/driver_providers.dart';
import 'package:teletech_drivers/features/drivers_admin/presentation/widgets/driver_picker_sheet.dart';

import 'package:teletech_drivers/features/place/presentation/providers/place_providers.dart';
import 'package:teletech_drivers/features/place/presentation/utils/place_coordinate_lookup.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip.dart';
import 'package:teletech_drivers/features/trip/domain/states/trip_status_machine.dart';
import 'package:teletech_drivers/features/trip/presentation/providers/trip_providers.dart';
import 'package:teletech_drivers/features/trip/presentation/widgets/trip_confirmation_summary.dart';
import 'package:teletech_drivers/features/trip/presentation/widgets/trip_events_section.dart';
import 'package:teletech_drivers/features/trip/presentation/widgets/trip_report_section.dart';
import 'package:teletech_drivers/features/trip/presentation/widgets/trip_status_chip.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request.dart';
import 'package:teletech_drivers/features/trip_request/presentation/providers/trip_request_providers.dart';
import 'package:teletech_drivers/features/trip_request/presentation/widgets/own_trip_report_section.dart';
import 'package:teletech_drivers/features/trip_request/presentation/widgets/request_tracking_section.dart';
import 'package:teletech_drivers/features/trip_request/presentation/widgets/trip_place_line.dart';

/// Trip details for drivers admin: progress, assign / reassign / cancel.
class DriversAdminTripDetailsScreen extends ConsumerWidget {
  const DriversAdminTripDetailsScreen({
    required this.tripId,
    this.openAssignOnLoad = false,
    super.key,
  });

  final String tripId;
  final bool openAssignOnLoad;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // Observer: stream so in-progress trip reports refresh live.
    final tripAsync = ref.watch(watchTripByIdProvider(tripId));

    ref.listen(tripAssignmentControllerProvider, (previous, next) {
      final failure = next.failure;
      if (failure == null || identical(previous?.failure, failure)) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure.message(l10n))));
    });

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
          return _TripDetailsBody(
            trip: trip,
            openAssignOnLoad: openAssignOnLoad,
          );
        },
      ),
    );
  }
}

class _TripDetailsBody extends ConsumerStatefulWidget {
  const _TripDetailsBody({required this.trip, this.openAssignOnLoad = false});

  final Trip trip;
  final bool openAssignOnLoad;

  @override
  ConsumerState<_TripDetailsBody> createState() => _TripDetailsBodyState();
}

class _TripDetailsBodyState extends ConsumerState<_TripDetailsBody> {
  var _didOpenAssign = false;

  Trip get trip => widget.trip;

  @override
  void initState() {
    super.initState();
    if (widget.openAssignOnLoad) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _didOpenAssign) return;
        if (!TripStatusMachine.canAssign(trip.status)) return;
        _didOpenAssign = true;
        _assignOrReassign();
      });
    }
  }

  Future<void> _assignOrReassign() async {
    final context = this.context;
    final l10n = AppLocalizations.of(context);
    final isReassign = TripStatusMachine.canReassign(trip.status);
    final selected = await DriverPickerSheet.show(
      context,
      trip: trip,
      excludeDriverId: isReassign ? trip.driverId : null,
    );
    if (selected == null || !context.mounted) return;

    final controller = ref.read(tripAssignmentControllerProvider.notifier);
    final succeeded = isReassign
        ? await controller.reassign(tripId: trip.id, driverId: selected.id)
        : await controller.assign(tripId: trip.id, driverId: selected.id);

    if (!context.mounted || !succeeded) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isReassign ? l10n.tripDriverReassigned : l10n.tripDriverAssigned,
        ),
      ),
    );
  }

  Future<void> _cancel() async {
    final context = this.context;
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.cancelTripConfirmTitle),
          content: Text(l10n.cancelTripConfirmMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.dialogCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.confirmCancelTrip),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) return;

    final succeeded = await ref
        .read(tripAssignmentControllerProvider.notifier)
        .cancel(trip.id);
    if (!context.mounted || !succeeded) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.tripCancelled)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context);
    final languageCode = locale.languageCode;
    final dateFormat = DateFormat.yMMMd(locale.toString()).add_jm();
    final actionState = ref.watch(tripAssignmentControllerProvider);
    final driversAsync = ref.watch(allDriversProvider);
    final resolver = ref.watch(placeNameResolverProvider);
    final canAssign = TripStatusMachine.canAssign(trip.status);
    final canReassign = TripStatusMachine.canReassign(trip.status);
    final canCancel = TripStatusMachine.canCancel(trip.status);
    final isBusy = actionState.isLoading && actionState.activeTripId == trip.id;
    final joinedIds = trip.requestIds.join(',');
    final requestsAsync = ref.watch(tripRequestsByIdsProvider(joinedIds));

    final assignedDriverName = _driverName(
      driversAsync,
      trip.driverId,
      languageCode,
      l10n,
    );
    final ownsReport =
        ownPendingReportRequestId(
          ref.watch(currentUserProvider).asData?.value,
          trip,
        ) !=
        null;

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
            StatusChip(
              label: tripStageLabel(trip, l10n),
              color: StatusChip.colorForTrip(trip.status),
            ),
          ],
        ),
        if (!ownsReport) TripConfirmationSummary(trip: trip),
        if (trip.tracking != null) ...[
          const SizedBox(height: 16),
          RequestTrackingSection(tracking: trip.tracking!),
        ],
        OwnTripReportSection(trip: trip),
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
        if (trip.driverId != null) ...[
          const SizedBox(height: 8),
          Text(
            l10n.tripAssignedDriverValue(assignedDriverName),
            style: textTheme.bodyLarge,
          ),
        ],
        if (trip.status.isInProgress && trip.driverId != null) ...[
          const SizedBox(height: 12),
          AppButton(
            label: l10n.openLiveMap,
            variant: AppButtonVariant.outlined,
            onPressed: () {
              context.push(
                AppRoutes.driversAdminLiveMapPath(driverId: trip.driverId),
              );
            },
          ),
        ],
        const SizedBox(height: 16),
        TripEventsSection(trip: trip),
        if (TripReportSection.shouldShow(trip)) ...[
          const SizedBox(height: 20),
          TripReportSection(trip: trip),
        ],
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
        const SizedBox(height: 24),
        if (canAssign || canReassign)
          FilledButton(
            onPressed: isBusy ? null : _assignOrReassign,
            child: isBusy
                ? SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  )
                : Text(canReassign ? l10n.reassignDriver : l10n.assignDriver),
          ),
        if (canCancel) ...[
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: isBusy ? null : _cancel,
            child: Text(l10n.cancelTrip),
          ),
        ],
      ],
    );
  }

  String _driverName(
    AsyncValue<List<AppUser>> driversAsync,
    String? driverId,
    String languageCode,
    AppLocalizations l10n,
  ) {
    if (driverId == null) return l10n.homeEmpty;
    final drivers = driversAsync.asData?.value;
    if (drivers == null) return driverId;
    for (final driver in drivers) {
      if (driver.id == driverId) {
        return driver.localizedName(languageCode);
      }
    }
    return driverId;
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
