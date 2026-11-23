import 'package:flutter/material.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/widgets/status_chip.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request_status.dart';

/// Colored status label for a trip request card.
class TripRequestStatusChip extends StatelessWidget {
  const TripRequestStatusChip({required this.status, super.key});

  final TripRequestStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return StatusChip.forTripRequest(
      status: status,
      label: status.label(l10n),
    );
  }
}

extension TripRequestStatusLabels on TripRequestStatus {
  String label(AppLocalizations l10n) {
    return switch (this) {
      TripRequestStatus.pending => l10n.tripRequestStatusPending,
      TripRequestStatus.approved => l10n.tripRequestStatusApproved,
      TripRequestStatus.rejected => l10n.tripRequestStatusRejected,
      TripRequestStatus.cancelled => l10n.tripRequestStatusCancelled,
    };
  }
}
