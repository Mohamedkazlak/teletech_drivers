import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/presentation/role_label.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/request_tracking.dart';
import 'package:teletech_drivers/features/trip_request/presentation/utils/request_tracking_labels.dart';

/// Vertical lifecycle for one requester: approval, driver, and current stage.
class RequestTrackingSection extends StatelessWidget {
  const RequestTrackingSection({required this.tracking, super.key});

  final RequestTracking tracking;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final languageCode = locale.languageCode;
    final dateFormat = DateFormat.yMMMd(locale.toString()).add_jm();
    final textTheme = Theme.of(context).textTheme;
    final reason = tracking.rejectionReason?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (tracking.stage == RequestTrackingStage.rejected) ...[
          _RejectionBanner(title: l10n.trackingRejectionTitle, reason: reason),
          const SizedBox(height: 16),
        ],
        _Answer(
          question: l10n.trackingApprovedQuestion,
          answer: _approvedAnswer(l10n, dateFormat),
        ),
        _Answer(
          question: l10n.trackingDriverQuestion,
          answer: _driverAnswer(l10n, languageCode, dateFormat),
        ),
        _Answer(
          question: l10n.trackingNowQuestion,
          answer: _nowAnswer(l10n, dateFormat),
        ),
        if (tracking.scheduledAt != null) ...[
          const SizedBox(height: 8),
          Text(
            l10n.trackingScheduled(
              dateFormat.format(tracking.scheduledAt!.toLocal()),
            ),
            style: textTheme.bodyMedium,
          ),
        ],
        if (tracking.vehicle != null) ...[
          const SizedBox(height: 4),
          Text(
            l10n.trackingVehicle(tracking.vehicle!.carLicense),
            style: textTheme.bodyMedium,
          ),
        ],
        const SizedBox(height: 16),
        for (var i = 0; i < tracking.timeline.length; i++)
          _TimelineRow(
            event: tracking.timeline[i],
            label: trackingStageLabel(tracking.timeline[i].stage, l10n),
            timeLabel: tracking.timeline[i].reachedAt == null
                ? null
                : dateFormat.format(tracking.timeline[i].reachedAt!.toLocal()),
            actorLabel: tracking.timeline[i].actorRole == null
                ? null
                : roleLabel(tracking.timeline[i].actorRole!, l10n),
            isLast: i == tracking.timeline.length - 1,
            isCurrent: tracking.timeline[i].stage == tracking.stage,
          ),
      ],
    );
  }

  String _approvedAnswer(AppLocalizations l10n, DateFormat dateFormat) {
    if (tracking.stage == RequestTrackingStage.rejected) {
      return l10n.trackingStageRejected;
    }
    final approved = tracking.eventFor(RequestTrackingStage.approved);
    if (approved != null && approved.reachedAt != null) {
      return l10n.trackingApprovedAt(
        dateFormat.format(approved.reachedAt!.toLocal()),
      );
    }
    return l10n.trackingPendingApproval;
  }

  String _driverAnswer(
    AppLocalizations l10n,
    String languageCode,
    DateFormat dateFormat,
  ) {
    final driver = tracking.driver;
    if (driver == null) return l10n.trackingNotYet;
    final name = driver.localizedName(languageCode) ?? l10n.trackingNotYet;
    final phone = driver.phone?.trim();
    final contact = l10n.trackingDriverLine(
      name,
      phone == null || phone.isEmpty ? l10n.trackingNoPhone : phone,
    );
    final assigned = tracking.eventFor(RequestTrackingStage.driverAssigned);
    if (assigned?.reachedAt == null) return contact;
    return '$contact · ${dateFormat.format(assigned!.reachedAt!.toLocal())}';
  }

  String _nowAnswer(AppLocalizations l10n, DateFormat dateFormat) {
    final label = trackingStageLabel(tracking.stage, l10n);
    final current = tracking.eventFor(tracking.stage);
    if (current?.reachedAt == null) return label;
    return '$label · ${dateFormat.format(current!.reachedAt!.toLocal())}';
  }
}

class _RejectionBanner extends StatelessWidget {
  const _RejectionBanner({required this.title, required this.reason});

  final String title;
  final String? reason;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: AppColors.statusRejected.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(12, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: textTheme.titleSmall?.copyWith(
                color: AppColors.statusRejected,
              ),
            ),
            if (reason != null && reason!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(reason!, style: textTheme.bodyLarge),
            ],
          ],
        ),
      ),
    );
  }
}

class _Answer extends StatelessWidget {
  const _Answer({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question, style: textTheme.labelLarge),
          const SizedBox(height: 2),
          Text(answer, style: textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.event,
    required this.label,
    required this.isLast,
    required this.isCurrent,
    this.timeLabel,
    this.actorLabel,
  });

  final RequestTrackingEvent event;
  final String label;
  final String? timeLabel;
  final String? actorLabel;
  final bool isLast;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final reached = event.isReached;
    final color = reached
        ? (isCurrent ? AppColors.deepBlue : AppColors.success)
        : AppColors.lightBlue;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Icon(
                  reached ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 22,
                  color: color,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: reached
                          ? AppColors.success.withValues(alpha: 0.5)
                          : AppColors.lightBlue.withValues(alpha: 0.5),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsetsDirectional.only(bottom: isLast ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: textTheme.titleSmall?.copyWith(color: color),
                  ),
                  if (timeLabel != null) ...[
                    const SizedBox(height: 2),
                    Text(timeLabel!, style: textTheme.bodySmall),
                  ],
                  if (actorLabel != null) ...[
                    const SizedBox(height: 2),
                    Text(actorLabel!, style: textTheme.bodySmall),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
