import 'package:flutter/material.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/request_tracking.dart';

String trackingChipLabel(RequestTrackingStage stage, AppLocalizations l10n) {
  return switch (stage) {
    RequestTrackingStage.submitted => l10n.tripRequestStatusPending,
    RequestTrackingStage.approved => l10n.tripRequestStatusApproved,
    RequestTrackingStage.driverAssigned => l10n.trackingChipDriverAssigned,
    RequestTrackingStage.inProgress => l10n.tripsInProgressTab,
    RequestTrackingStage.finished ||
    RequestTrackingStage.awaitingConfirmation ||
    RequestTrackingStage.confirmed ||
    RequestTrackingStage.unconfirmed => l10n.tripStatusCompleted,
    RequestTrackingStage.rejected => l10n.tripRequestStatusRejected,
    RequestTrackingStage.cancelled => l10n.tripRequestStatusCancelled,
  };
}

String trackingStageLabel(RequestTrackingStage stage, AppLocalizations l10n) {
  return switch (stage) {
    RequestTrackingStage.submitted => l10n.trackingStageSubmitted,
    RequestTrackingStage.approved => l10n.trackingStageApproved,
    RequestTrackingStage.rejected => l10n.trackingStageRejected,
    RequestTrackingStage.driverAssigned => l10n.trackingStageDriverAssigned,
    RequestTrackingStage.inProgress => l10n.trackingStageInProgress,
    RequestTrackingStage.finished => l10n.trackingStageFinished,
    RequestTrackingStage.awaitingConfirmation =>
      l10n.trackingStageAwaitingConfirmation,
    RequestTrackingStage.confirmed => l10n.trackingStageConfirmed,
    RequestTrackingStage.unconfirmed => l10n.trackingStageUnconfirmed,
    RequestTrackingStage.cancelled => l10n.trackingStageCancelled,
  };
}

Color trackingChipColor(RequestTrackingStage stage) {
  return switch (stage) {
    RequestTrackingStage.submitted => AppColors.statusPending,
    RequestTrackingStage.approved => AppColors.statusApproved,
    RequestTrackingStage.driverAssigned => AppColors.statusAssigned,
    RequestTrackingStage.inProgress => AppColors.statusInProgress,
    RequestTrackingStage.finished ||
    RequestTrackingStage.awaitingConfirmation ||
    RequestTrackingStage.confirmed ||
    RequestTrackingStage.unconfirmed => AppColors.statusCompleted,
    RequestTrackingStage.rejected ||
    RequestTrackingStage.cancelled => AppColors.statusRejected,
  };
}
