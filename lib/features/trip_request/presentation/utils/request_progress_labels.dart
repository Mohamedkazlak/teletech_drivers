import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/request_progress_step_id.dart';

extension RequestProgressStepIdLabel on RequestProgressStepId {
  String label(AppLocalizations l10n) {
    return switch (this) {
      RequestProgressStepId.requested => l10n.requestProgressStepRequested,
      RequestProgressStepId.approved => l10n.requestProgressStepApproved,
      RequestProgressStepId.driverAssigned =>
        l10n.requestProgressStepDriverAssigned,
      RequestProgressStepId.going => l10n.requestProgressStepGoing,
      RequestProgressStepId.arrived => l10n.requestProgressStepArrived,
      RequestProgressStepId.returning => l10n.requestProgressStepReturning,
      RequestProgressStepId.completed => l10n.requestProgressStepCompleted,
    };
  }
}
