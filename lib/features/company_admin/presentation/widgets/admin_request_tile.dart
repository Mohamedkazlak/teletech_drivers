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

/// Request row for company admin: status, branch, approve/reject when pending.
class AdminRequestTile extends ConsumerWidget {
  const AdminRequestTile({
    required this.request,
    required this.onTap,
    this.onApprove,
    this.onReject,
    this.isApproving = false,
    this.isRejecting = false,
    this.animateIndex,
    super.key,
  });

  final TripRequest request;
  final VoidCallback onTap;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final bool isApproving;
  final bool isRejecting;
  final int? animateIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context);
    final languageCode = locale.languageCode;
    final dateFormat = DateFormat.yMMMd(locale.toString()).add_jm();
    final pending = request.status == TripRequestStatus.pending;
    final busy = isApproving || isRejecting;
    final statusLabel = request.status.label(l10n);
    final statusColor = StatusChip.colorForTripRequest(request.status);
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
      onTap: busy ? null : onTap,
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
            const SizedBox(height: 8),
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
        ],
      ),
      footer: pending
          ? Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: busy ? null : onReject,
                  child: isRejecting
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.rejectTripRequest),
                ),
                const SizedBox(width: 4),
                FilledButton(
                  onPressed: busy ? null : onApprove,
                  child: isApproving
                      ? SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        )
                      : Text(l10n.approveTripRequest),
                ),
              ],
            )
          : null,
    );
  }
}
