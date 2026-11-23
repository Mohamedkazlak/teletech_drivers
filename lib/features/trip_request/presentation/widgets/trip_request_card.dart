import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/widgets/status_chip.dart';
import 'package:teletech_drivers/core/widgets/trip_card.dart';
import 'package:teletech_drivers/features/place/presentation/providers/place_providers.dart';
import 'package:teletech_drivers/features/trip/presentation/widgets/trip_status_chip.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request.dart';
import 'package:teletech_drivers/features/trip_request/presentation/utils/request_tracking_labels.dart';
import 'package:teletech_drivers/features/trip_request/presentation/widgets/custom_location_chip.dart';
import 'package:teletech_drivers/features/trip_request/presentation/widgets/trip_request_status_chip.dart';

/// Summary card for one of the employee's trip requests.
class TripRequestCard extends ConsumerWidget {
  const TripRequestCard({
    required this.request,
    required this.onCancel,
    this.onOpen,
    this.isCancelling = false,
    this.animateIndex,
    super.key,
  });

  final TripRequest request;
  final VoidCallback onCancel;
  final VoidCallback? onOpen;
  final bool isCancelling;
  final int? animateIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context);
    final languageCode = locale.languageCode;
    final dateFormat = DateFormat.yMMMd(locale.toString()).add_jm();
    final statusLabel = _statusLabel(request, l10n);
    final statusColor = _statusColor(request);
    final resolver = ref.watch(placeNameResolverProvider);
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

    final hasCustom = request.hasCustomPickupLocation ||
        request.hasCustomDestinationLocation;
    final hasNotes = request.notes.isNotEmpty;
    final linkedTrip = request.linkedTrip;
    final driverName = linkedTrip?.localizedDriverName(languageCode);
    final tripStatusLine = linkedTrip == null
        ? null
        : l10n.tripStatusLine(linkedTrip.status.label(l10n));

    return TripCard(
      animateIndex: animateIndex,
      onTap: onOpen,
      title: l10n.tripRouteSummary(pickupName, destinationName),
      statusLabel: statusLabel,
      statusColor: statusColor,
      leadingIcon: Icons.route_outlined,
      subtitle: l10n.tripRequestWhenValue(
        dateFormat.format(request.requestedDateTime.toLocal()),
      ),
      trailing: (hasCustom || hasNotes || driverName != null || tripStatusLine != null)
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (tripStatusLine != null)
                  Text(tripStatusLine, style: textTheme.bodyMedium),
                if (driverName != null)
                  Text(
                    l10n.myTripsDriverName(driverName),
                    style: textTheme.bodyMedium,
                  ),
                if (hasCustom) ...[
                  if (driverName != null) const SizedBox(height: 4),
                  const CustomLocationChip(),
                ],
                if (hasNotes) ...[
                  if (hasCustom || driverName != null) const SizedBox(height: 4),
                  Text(
                    l10n.tripRequestNotesValue(request.notes),
                    style: textTheme.bodySmall,
                  ),
                ],
              ],
            )
          : null,
      footer: request.canCancel
          ? Align(
              alignment: AlignmentDirectional.centerEnd,
              child: TextButton(
                onPressed: isCancelling ? null : onCancel,
                child: isCancelling
                    ? SizedBox.square(
                        dimension: 18,
                        child: Semantics(
                          label: l10n.loading,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    : Text(l10n.cancelTripRequest),
              ),
            )
          : null,
    );
  }
}

String _statusLabel(TripRequest request, AppLocalizations l10n) {
  final tracking = request.tracking;
  if (tracking != null) return trackingChipLabel(tracking.stage, l10n);
  final trip = request.linkedTrip;
  if (trip != null) return trip.status.label(l10n);
  return request.status.label(l10n);
}

Color _statusColor(TripRequest request) {
  final tracking = request.tracking;
  if (tracking != null) return trackingChipColor(tracking.stage);
  final trip = request.linkedTrip;
  if (trip != null) return StatusChip.colorForTrip(trip.status);
  return StatusChip.colorForTripRequest(request.status);
}
