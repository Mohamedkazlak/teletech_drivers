import 'package:flutter/material.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/request_progress.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/request_progress_step_id.dart';
import 'package:teletech_drivers/features/trip_request/presentation/utils/request_progress_labels.dart';

/// Compact progress indicator: bar + current (or failed) step label.
class RequestProgressBar extends StatelessWidget {
  const RequestProgressBar({required this.progress, super.key});

  final RequestProgress progress;

  static final _totalSteps = RequestProgressStepId.values.length;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final failed = progress.failedStep;
    final current = progress.currentStep;

    final String label;
    final Color color;
    final double rawValue;
    if (failed != null) {
      label = l10n.requestProgressFailedStep(failed.id.label(l10n));
      color = AppColors.error;
      rawValue = (failed.id.index + 1) / _totalSteps;
    } else if (current != null) {
      label = l10n.requestProgressCurrentStep(current.id.label(l10n));
      color = AppColors.deepBlue;
      rawValue = (current.id.index + 0.5) / _totalSteps;
    } else {
      label = l10n.requestProgressStepCompleted;
      color = AppColors.success;
      rawValue = 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: rawValue.clamp(0.05, 1.0),
            minHeight: 6,
            backgroundColor: AppColors.paleBlue,
            color: color,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(color: color),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
