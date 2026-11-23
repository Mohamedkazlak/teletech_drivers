import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/presentation/app_loading_indicator.dart';
import 'package:teletech_drivers/core/presentation/branch_label.dart';
import 'package:teletech_drivers/core/utils/failure_messages.dart';
import 'package:teletech_drivers/core/widgets/app_scaffold.dart';
import 'package:teletech_drivers/core/widgets/list_failure_view.dart';
import 'package:teletech_drivers/core/widgets/status_chip.dart';
import 'package:teletech_drivers/features/place/presentation/providers/place_providers.dart';
import 'package:teletech_drivers/features/trip/presentation/widgets/trip_status_chip.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/linked_trip.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_confirmation_status.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request.dart';
import 'package:teletech_drivers/features/trip_request/presentation/providers/trip_request_providers.dart';
import 'package:teletech_drivers/features/trip_request/presentation/widgets/confirm_trip_form.dart';
import 'package:teletech_drivers/features/trip_request/presentation/widgets/request_tracking_section.dart';
import 'package:teletech_drivers/features/trip_request/presentation/utils/request_tracking_labels.dart';
import 'package:teletech_drivers/features/trip_request/presentation/widgets/trip_request_status_chip.dart';

/// Own trip request: fields, linked trip, and the confirmation report.
class TripRequestDetailsScreen extends ConsumerWidget {
  const TripRequestDetailsScreen({required this.requestId, super.key});

  final String requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final requestAsync = ref.watch(watchTripRequestByIdProvider(requestId));

    return AppScaffold(
      title: l10n.tripRequestDetailsTitle,
      showBackButton: true,
      body: requestAsync.when(
        skipLoadingOnReload: true,
        loading: () => Center(child: AppLoadingIndicator(label: l10n.loading)),
        error: (error, _) => ListFailureView(
          message: messageForError(error, l10n),
          onRetry: () =>
              ref.invalidate(watchTripRequestByIdProvider(requestId)),
        ),
        data: (request) {
          if (request == null) {
            return Center(child: Text(l10n.errorNotFound));
          }
          return _DetailsBody(request: request);
        },
      ),
    );
  }
}

class _RequestStatusChip extends StatelessWidget {
  const _RequestStatusChip({required this.request});

  final TripRequest request;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tracking = request.tracking;
    if (tracking == null) {
      return TripRequestStatusChip(status: request.status);
    }
    return StatusChip(
      label: trackingChipLabel(tracking.stage, l10n),
      color: trackingChipColor(tracking.stage),
    );
  }
}

class _DetailsBody extends ConsumerWidget {
  const _DetailsBody({required this.request});

  final TripRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final languageCode = locale.languageCode;
    final dateFormat = DateFormat.yMMMd(locale.toString()).add_jm();
    final resolver = ref.watch(placeNameResolverProvider);
    final pickup = resolver.resolve(
      storedName: request.pickupPlaceName,
      languageCode: languageCode,
      placeId: request.pickupPlaceId,
    );
    final destination = resolver.resolve(
      storedName: request.destinationPlaceName,
      languageCode: languageCode,
      placeId: request.destinationPlaceId,
    );
    final trip = request.linkedTrip;

    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 32),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.tripRouteSummary(pickup, destination),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            _RequestStatusChip(request: request),
          ],
        ),
        if (request.tracking != null) ...[
          const SizedBox(height: 16),
          RequestTrackingSection(tracking: request.tracking!),
        ],
        const SizedBox(height: 16),
        _Field(label: l10n.detailPickup, value: pickup),
        if (_present(request.pickupAddress))
          _Field(label: l10n.detailAddress, value: request.pickupAddress!),
        _Field(label: l10n.detailDestination, value: destination),
        if (_present(request.destinationAddress))
          _Field(
            label: l10n.detailAddress,
            value: request.destinationAddress!,
          ),
        _Field(
          label: l10n.detailRequestedAt,
          value: dateFormat.format(request.requestedDateTime.toLocal()),
        ),
        _Field(
          label: l10n.detailNotes,
          value: _present(request.notes) ? request.notes : l10n.detailNoNotes,
        ),
        if (_present(request.employeeName))
          _Field(label: l10n.detailEmployee, value: request.employeeName),
        if (_present(request.employeePhone))
          _Field(label: l10n.detailPhone, value: request.employeePhone!),
        if (request.employeeBranch != null)
          _Field(
            label: l10n.detailBranch,
            value: branchLabel(request.employeeBranch!, l10n),
          ),
        if (request.tracking == null && _present(request.rejectionReason))
          _Field(
            label: l10n.detailRejectionReason,
            value: request.rejectionReason!,
          ),
        if (request.handledAt != null)
          _Field(
            label: l10n.detailHandledAt,
            value: dateFormat.format(request.handledAt!.toLocal()),
          ),
        if (trip != null) ...[
          const SizedBox(height: 8),
          _TripBlock(
            requestId: request.id,
            trip: trip,
            languageCode: languageCode,
          ),
        ],
      ],
    );
  }

  bool _present(String? value) => value != null && value.trim().isNotEmpty;
}

class _TripBlock extends StatelessWidget {
  const _TripBlock({
    required this.requestId,
    required this.trip,
    required this.languageCode,
  });

  final String requestId;
  final LinkedTrip trip;
  final String languageCode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final driver = trip.localizedDriverName(languageCode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.tripBlockTitle, style: textTheme.titleMedium),
        const SizedBox(height: 8),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TripStatusChip(status: trip.status),
        ),
        const SizedBox(height: 12),
        Text(
          driver == null
              ? l10n.tripBlockNoDriver
              : l10n.myTripsDriverName(driver),
          style: textTheme.bodyLarge,
        ),
        const SizedBox(height: 12),
        _Confirmation(requestId: requestId, trip: trip),
      ],
    );
  }
}

class _Confirmation extends StatelessWidget {
  const _Confirmation({required this.requestId, required this.trip});

  final String requestId;
  final LinkedTrip trip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    if (trip.needsReport) {
      return ConfirmTripForm(requestId: requestId);
    }

    final status = trip.confirmationStatus;
    if (status == TripConfirmationStatus.unconfirmed) {
      return Text(l10n.confirmationUnconfirmed, style: textTheme.bodyLarge);
    }
    if (status == TripConfirmationStatus.confirmed) {
      final showedUp = trip.driverShowedUp;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.confirmationConfirmed, style: textTheme.titleSmall),
          if (showedUp != null) ...[
            const SizedBox(height: 4),
            Text(
              showedUp ? l10n.driverShowedUpYes : l10n.driverShowedUpNo,
              style: textTheme.bodyLarge,
            ),
          ],
        ],
      );
    }
    if (status == TripConfirmationStatus.pending) {
      return Text(l10n.confirmationPending, style: textTheme.bodyLarge);
    }
    return const SizedBox.shrink();
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: textTheme.labelLarge),
          const SizedBox(height: 2),
          Text(value, style: textTheme.bodyLarge),
        ],
      ),
    );
  }
}
