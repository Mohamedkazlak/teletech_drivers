import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/widgets/app_scaffold.dart';
import 'package:teletech_drivers/core/presentation/app_loading_indicator.dart';
import 'package:teletech_drivers/core/presentation/requester_contact_section.dart';
import 'package:teletech_drivers/core/utils/failure_messages.dart';
import 'package:teletech_drivers/features/place/presentation/providers/place_providers.dart';
import 'package:teletech_drivers/features/place/presentation/utils/place_coordinate_lookup.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request.dart';
import 'package:teletech_drivers/features/trip_request/presentation/providers/trip_request_providers.dart';
import 'package:teletech_drivers/features/trip_request/presentation/widgets/trip_place_line.dart';
import 'package:teletech_drivers/features/trip_request/presentation/widgets/trip_request_status_chip.dart';

/// Company admin request detail: requester contact + route (no other phones).
class CompanyAdminRequestDetailsScreen extends ConsumerWidget {
  const CompanyAdminRequestDetailsScreen({required this.requestId, super.key});

  final String requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final requestAsync = ref.watch(tripRequestByIdProvider(requestId));

    return AppScaffold(
      title: l10n.requestDetailsTitle,
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
          return _RequestDetailsBody(request: request);
        },
      ),
    );
  }
}

class _RequestDetailsBody extends ConsumerWidget {
  const _RequestDetailsBody({required this.request});

  final TripRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context);
    final languageCode = locale.languageCode;
    final dateFormat = DateFormat.yMMMd(locale.toString()).add_jm();
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

    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(destinationName, style: textTheme.headlineSmall),
            ),
            TripRequestStatusChip(status: request.status),
          ],
        ),
        const SizedBox(height: 16),
        RequesterContactSection(
          name: request.employeeName,
          branch: request.employeeBranch,
          phone: request.employeePhone,
        ),
        const SizedBox(height: 20),
        TripPlaceLine(
          text: l10n.tripRequestPickupValue(pickupName),
          style: textTheme.bodyLarge,
          showCustomChip: request.hasCustomPickupLocation,
          address: request.pickupAddress,
          latitude: pickupCoords.latitude,
          longitude: pickupCoords.longitude,
        ),
        const SizedBox(height: 4),
        TripPlaceLine(
          text: l10n.tripRequestDestinationValue(destinationName),
          style: textTheme.bodyLarge,
          showCustomChip: request.hasCustomDestinationLocation,
          address: request.destinationAddress,
          latitude: destinationCoords.latitude,
          longitude: destinationCoords.longitude,
        ),
        const SizedBox(height: 4),
        Text(
          l10n.tripRequestWhenValue(
            dateFormat.format(request.requestedDateTime.toLocal()),
          ),
          style: textTheme.bodyLarge,
        ),
        if (request.notes.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            l10n.tripRequestNotesValue(request.notes),
            style: textTheme.bodyMedium,
          ),
        ],
        if (request.rejectionReason != null &&
            request.rejectionReason!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(l10n.rejectionReasonLabel, style: textTheme.titleSmall),
          Text(request.rejectionReason!, style: textTheme.bodyMedium),
        ],
        if (request.handledByName != null) ...[
          const SizedBox(height: 12),
          Text(
            l10n.handledByValue(request.handledByName!),
            style: textTheme.bodySmall,
          ),
        ],
        if (request.handledAt != null) ...[
          const SizedBox(height: 4),
          Text(
            l10n.handledAtValue(
              dateFormat.format(request.handledAt!.toLocal()),
            ),
            style: textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}
