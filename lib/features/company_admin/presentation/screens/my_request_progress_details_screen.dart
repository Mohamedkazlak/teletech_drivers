import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/presentation/app_loading_indicator.dart';
import 'package:teletech_drivers/core/utils/failure_messages.dart';
import 'package:teletech_drivers/core/widgets/app_scaffold.dart';
import 'package:teletech_drivers/core/widgets/status_chip.dart';
import 'package:teletech_drivers/features/auth/domain/entities/app_user.dart';
import 'package:teletech_drivers/features/auth/presentation/providers/auth_providers.dart';
import 'package:teletech_drivers/features/drivers_admin/presentation/providers/driver_providers.dart';
import 'package:teletech_drivers/features/place/presentation/providers/place_providers.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip.dart';
import 'package:teletech_drivers/features/trip/presentation/providers/trip_providers.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request.dart';
import 'package:teletech_drivers/features/trip_request/domain/mappers/request_progress_mapper.dart';
import 'package:teletech_drivers/features/trip_request/presentation/controllers/cancel_trip_request_controller.dart';
import 'package:teletech_drivers/features/trip_request/presentation/providers/trip_request_providers.dart';
import 'package:teletech_drivers/features/trip_request/presentation/utils/request_tracking_labels.dart';
import 'package:teletech_drivers/features/trip_request/presentation/widgets/confirm_trip_form.dart';
import 'package:teletech_drivers/features/trip_request/presentation/widgets/request_progress_timeline.dart';
import 'package:teletech_drivers/features/trip_request/presentation/widgets/request_tracking_section.dart';
import 'package:teletech_drivers/features/trip_request/presentation/widgets/trip_request_status_chip.dart';

/// Own-request details: live timeline, driver contact, notes, cancel.
class MyRequestProgressDetailsScreen extends ConsumerWidget {
  const MyRequestProgressDetailsScreen({required this.requestId, super.key});

  final String requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final requestAsync = ref.watch(watchTripRequestByIdProvider(requestId));

    return AppScaffold(
      title: l10n.myRequestProgressTitle,
      showBackButton: true,
      body: requestAsync.when(
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
        data: (request) {
          if (request == null) {
            return Center(
              child: Text(
                l10n.errorNotFound,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            );
          }
          return _DetailsBody(request: request);
        },
      ),
    );
  }
}

class _DetailsBody extends ConsumerWidget {
  const _DetailsBody({required this.request});

  final TripRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripId = request.tripId;
    if (request.tracking != null || tripId == null || tripId.isEmpty) {
      return _DetailsContent(request: request, trip: null);
    }

    final tripAsync = ref.watch(watchTripByIdProvider(tripId));
    return tripAsync.when(
      loading: () {
        final l10n = AppLocalizations.of(context);
        return Center(child: AppLoadingIndicator(label: l10n.loading));
      },
      error: (error, _) {
        final l10n = AppLocalizations.of(context);
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              messageForError(error, l10n),
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
      data: (trip) => _DetailsContent(request: request, trip: trip),
    );
  }
}

class _DetailsContent extends ConsumerWidget {
  const _DetailsContent({required this.request, required this.trip});

  final TripRequest request;
  final Trip? trip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context);
    final languageCode = locale.languageCode;
    final dateFormat = DateFormat.yMMMd(locale.toString()).add_jm();
    final resolver = ref.watch(placeNameResolverProvider);
    final cancelState = ref.watch(cancelTripRequestControllerProvider);
    final drivers = ref.watch(allDriversProvider).asData?.value ?? const [];

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
    final progress = RequestProgressMapper.map(request, trip);
    final userId = ref.watch(currentUserProvider).asData?.value?.id;
    final linkedTrip = trip;
    final needsReport =
        request.linkedTrip?.needsReport == true ||
        (linkedTrip != null &&
            linkedTrip.pendingReportRequestIdFor(userId) == request.id);
    final trackedDriver = request.tracking?.driver;
    final driver = trackedDriver == null
        ? _findDriver(drivers, trip?.driverId)
        : null;

    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 32),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.tripRouteSummary(pickupName, destinationName),
                style: textTheme.titleLarge,
              ),
            ),
            StatusChip(
              label: request.tracking == null
                  ? request.status.label(l10n)
                  : trackingChipLabel(request.tracking!.stage, l10n),
              color: request.tracking == null
                  ? StatusChip.colorForTripRequest(request.status)
                  : trackingChipColor(request.tracking!.stage),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (needsReport) ...[
          ConfirmTripForm(requestId: request.id),
          const SizedBox(height: 16),
        ],
        Text(
          l10n.tripRequestWhenValue(
            dateFormat.format(request.requestedDateTime.toLocal()),
          ),
          style: textTheme.bodyLarge,
        ),
        const SizedBox(height: 20),
        if (request.tracking != null)
          RequestTrackingSection(tracking: request.tracking!)
        else ...[
          Text(l10n.myRequestProgressTitle, style: textTheme.titleMedium),
          const SizedBox(height: 12),
          RequestProgressTimeline(progress: progress),
        ],
        const SizedBox(height: 20),
        Text(l10n.assignedDriverSection, style: textTheme.titleMedium),
        const SizedBox(height: 8),
        if (trackedDriver != null) ...[
          Text(
            l10n.tripDriverNameValue(
              trackedDriver.localizedName(languageCode) ?? l10n.trackingNotYet,
            ),
            style: textTheme.bodyLarge,
          ),
          const SizedBox(height: 4),
          Text(
            l10n.assignedDriverPhoneValue(
              trackedDriver.phone?.trim().isNotEmpty == true
                  ? trackedDriver.phone!.trim()
                  : l10n.trackingNoPhone,
            ),
            style: textTheme.bodyLarge,
          ),
        ] else if (driver == null)
          Text(l10n.assignedDriverPending, style: textTheme.bodyLarge)
        else ...[
          Text(
            l10n.tripDriverNameValue(driver.localizedName(languageCode)),
            style: textTheme.bodyLarge,
          ),
          if (driver.phone != null && driver.phone!.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              l10n.assignedDriverPhoneValue(driver.phone!.trim()),
              style: textTheme.bodyLarge,
            ),
          ],
        ],
        if (request.notes.trim().isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(l10n.notesLabel, style: textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(request.notes, style: textTheme.bodyLarge),
        ],
        if (request.canCancel) ...[
          const SizedBox(height: 28),
          FilledButton(
            onPressed:
                cancelState.isLoading &&
                    cancelState.activeRequestId == request.id
                ? null
                : () => _confirmAndCancel(context, ref),
            child:
                cancelState.isLoading &&
                    cancelState.activeRequestId == request.id
                ? SizedBox.square(
                    dimension: 20,
                    child: Semantics(
                      label: l10n.loading,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : Text(l10n.cancelTripRequest),
          ),
        ],
      ],
    );
  }

  AppUser? _findDriver(List<AppUser> drivers, String? driverId) {
    if (driverId == null || driverId.isEmpty) return null;
    for (final driver in drivers) {
      if (driver.id == driverId) return driver;
    }
    return null;
  }

  Future<void> _confirmAndCancel(BuildContext context, WidgetRef ref) async {
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
