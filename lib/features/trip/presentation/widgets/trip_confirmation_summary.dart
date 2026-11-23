import 'package:flutter/material.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/core/widgets/status_chip.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_confirmation_status.dart';

/// Confirmation status and the no-show badge for a completed trip.
class TripConfirmationSummary extends StatelessWidget {
  const TripConfirmationSummary({required this.trip, super.key});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final status = trip.confirmationStatus;
    if (status == null && trip.driverShowedUp != false) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (status != null)
            Text(
              l10n.confirmationStatusValue(_confirmationLabel(status, l10n)),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          if (trip.driverShowedUp == false)
            StatusChip(label: l10n.driverDidNotShow, color: AppColors.error),
        ],
      ),
    );
  }
}

String _confirmationLabel(
  TripConfirmationStatus status,
  AppLocalizations l10n,
) {
  return switch (status) {
    TripConfirmationStatus.pending => l10n.confirmationPending,
    TripConfirmationStatus.confirmed => l10n.confirmationConfirmed,
    TripConfirmationStatus.unconfirmed => l10n.confirmationUnconfirmed,
  };
}
