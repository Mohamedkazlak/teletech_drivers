import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/presentation/branch_chip.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/core/widgets/status_chip.dart';
import 'package:teletech_drivers/core/widgets/trip_card.dart';
import 'package:teletech_drivers/features/place/presentation/providers/place_providers.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request_status.dart';
import 'package:teletech_drivers/features/trip_request/presentation/widgets/trip_request_status_chip.dart';

/// Selectable approved request for Drivers Admin trip creation.
class ApprovedRequestTile extends ConsumerWidget {
  const ApprovedRequestTile({
    required this.request,
    required this.selected,
    required this.onSelectedChanged,
    required this.onTap,
    this.selectable = true,
    this.animateIndex,
    super.key,
  });

  final TripRequest request;
  final bool selected;
  final ValueChanged<bool?> onSelectedChanged;
  final VoidCallback onTap;
  final bool selectable;
  final int? animateIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context);
    final languageCode = locale.languageCode;
    final dateFormat = DateFormat.yMMMd(locale.toString()).add_jm();
    final statusLabel = TripRequestStatus.approved.label(l10n);
    final statusColor = StatusChip.colorForTripRequest(
      TripRequestStatus.approved,
    );
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

    return TripCard(
      animateIndex: animateIndex,
      onTap: onTap,
      title: request.employeeName,
      statusLabel: statusLabel,
      statusColor: statusColor,
      leadingIcon: Icons.person_outline,
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (request.isAdminRequest)
                StatusChip(
                  label: l10n.adminRequestChip,
                  color: AppColors.deepBlue,
                ),
              if (request.employeeBranch != null)
                BranchChip(branch: request.employeeBranch),
            ],
          ),
          if (request.isAdminRequest || request.employeeBranch != null)
            const SizedBox(height: 6),
          Text(
            l10n.tripRequestPickupValue(pickupName),
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 2),
          Text(
            l10n.tripRequestDestinationValue(destinationName),
            style: textTheme.bodyMedium,
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
      footer: selectable
          ? Align(
              alignment: AlignmentDirectional.centerStart,
              child: Checkbox(value: selected, onChanged: onSelectedChanged),
            )
          : null,
    );
  }
}
