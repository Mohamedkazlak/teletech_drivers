import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/widgets/status_chip.dart';
import 'package:teletech_drivers/core/widgets/trip_card.dart';
import 'package:teletech_drivers/features/place/presentation/providers/place_providers.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request.dart';
import 'package:teletech_drivers/features/trip_request/domain/mappers/request_progress_mapper.dart';
import 'package:teletech_drivers/features/trip_request/presentation/widgets/request_progress_bar.dart';
import 'package:teletech_drivers/features/trip_request/presentation/widgets/trip_request_status_chip.dart';

/// Own-request summary card: route, datetime, status, compact progress.
class MyRequestCard extends ConsumerWidget {
  const MyRequestCard({
    required this.request,
    required this.onTap,
    this.trip,
    this.animateIndex,
    super.key,
  });

  final TripRequest request;
  final Trip? trip;
  final VoidCallback onTap;
  final int? animateIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final languageCode = locale.languageCode;
    final dateFormat = DateFormat.yMMMd(locale.toString()).add_jm();
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
    final progress = RequestProgressMapper.map(request, trip);

    return TripCard(
      animateIndex: animateIndex,
      onTap: onTap,
      title: l10n.tripRouteSummary(pickupName, destinationName),
      from: pickupName,
      to: destinationName,
      statusLabel: request.status.label(l10n),
      statusColor: StatusChip.colorForTripRequest(request.status),
      leadingIcon: Icons.route_outlined,
      subtitle: l10n.tripRequestWhenValue(
        dateFormat.format(request.requestedDateTime.toLocal()),
      ),
      footer: RequestProgressBar(progress: progress),
    );
  }
}
