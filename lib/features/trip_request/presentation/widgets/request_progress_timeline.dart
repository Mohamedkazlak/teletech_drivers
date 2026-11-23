import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/request_progress.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/request_progress_step.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/request_progress_step_state.dart';
import 'package:teletech_drivers/features/trip_request/presentation/utils/request_progress_labels.dart';

/// Full vertical timeline of request progress steps with timestamps.
class RequestProgressTimeline extends StatelessWidget {
  const RequestProgressTimeline({required this.progress, super.key});

  final RequestProgress progress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final dateFormat = DateFormat.yMMMd(locale.toString()).add_jm();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < progress.steps.length; i++)
          _TimelineRow(
            step: progress.steps[i],
            label: progress.steps[i].id.label(l10n),
            timeLabel: progress.steps[i].at == null
                ? null
                : dateFormat.format(progress.steps[i].at!.toLocal()),
            isLast: i == progress.steps.length - 1,
          ),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.step,
    required this.label,
    required this.isLast,
    this.timeLabel,
  });

  final RequestProgressStep step;
  final String label;
  final String? timeLabel;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final color = _colorFor(step.state);
    final icon = _iconFor(step.state);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Icon(icon, size: 22, color: color),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: step.state == RequestProgressStepState.done
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
                  if (step.failureReason != null &&
                      step.failureReason!.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      step.failureReason!,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _colorFor(RequestProgressStepState state) {
    return switch (state) {
      RequestProgressStepState.done => AppColors.success,
      RequestProgressStepState.current => AppColors.deepBlue,
      RequestProgressStepState.pending => AppColors.lightBlue,
      RequestProgressStepState.failed => AppColors.error,
    };
  }

  IconData _iconFor(RequestProgressStepState state) {
    return switch (state) {
      RequestProgressStepState.done => Icons.check_circle,
      RequestProgressStepState.current => Icons.radio_button_checked,
      RequestProgressStepState.pending => Icons.radio_button_unchecked,
      RequestProgressStepState.failed => Icons.cancel,
    };
  }
}
