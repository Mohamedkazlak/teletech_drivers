import 'package:flutter/material.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/widgets/status_chip.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_status.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_confirmation_status.dart';

/// Colored status label for a trip card.
class TripStatusChip extends StatelessWidget {
  const TripStatusChip({required this.status, super.key});

  final TripStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return StatusChip.forTrip(status: status, label: status.label(l10n));
  }
}

/// Completed trips still waiting on a report use the awaiting-report stage.
String tripStageLabel(Trip trip, AppLocalizations l10n) {
  if (trip.status == TripStatus.completed &&
      trip.confirmationStatus == TripConfirmationStatus.pending) {
    return l10n.tripsAwaitingReportTab;
  }
  return trip.status.label(l10n);
}

extension TripStatusLabels on TripStatus {
  String label(AppLocalizations l10n) {
    return switch (this) {
      TripStatus.unassigned => l10n.tripStatusUnassigned,
      TripStatus.assigned => l10n.tripStatusAssigned,
      TripStatus.going => l10n.tripStatusGoing,
      TripStatus.atDestination => l10n.tripStatusAtDestination,
      TripStatus.returning => l10n.tripStatusReturning,
      TripStatus.completed => l10n.tripStatusCompleted,
      TripStatus.cancelled => l10n.tripStatusCancelled,
    };
  }
}
