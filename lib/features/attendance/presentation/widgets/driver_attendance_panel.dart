import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/presentation/app_loading_indicator.dart';
import 'package:teletech_drivers/core/utils/failure_messages.dart';
import 'package:teletech_drivers/features/attendance/presentation/providers/attendance_providers.dart';
import 'package:teletech_drivers/features/attendance/presentation/widgets/adjust_attendance_dialog.dart';
import 'package:teletech_drivers/features/attendance/presentation/widgets/driver_attendance_section.dart';

/// Per-driver history and the adjust action on the driver profile.
class DriverAttendancePanel extends ConsumerStatefulWidget {
  const DriverAttendancePanel({required this.driverId, super.key});

  final String driverId;

  @override
  ConsumerState<DriverAttendancePanel> createState() =>
      _DriverAttendancePanelState();
}

class _DriverAttendancePanelState extends ConsumerState<DriverAttendancePanel> {
  var _period = 'week';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final history = ref.watch(
      driverAttendanceProvider((
        driverId: widget.driverId,
        period: _period,
        date: _panelDate(),
      )),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.attendanceCardTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            TextButton(
              onPressed: () async {
                final saved = await AdjustAttendanceDialog.show(
                  context,
                  driverId: widget.driverId,
                );
                if (saved == true) {
                  ref.invalidate(driverAttendanceProvider);
                  ref.invalidate(attendanceSummaryProvider);
                }
              },
              child: Text(l10n.attendanceAdjustTitle),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          children: [
            for (final period in const ['week', 'month', 'year'])
              ChoiceChip(
                label: Text(_panelPeriod(l10n, period)),
                selected: _period == period,
                onSelected: (_) => setState(() => _period = period),
              ),
          ],
        ),
        history.when(
          loading: () => AppLoadingIndicator(label: l10n.loading),
          error: (error, _) => Text(messageForError(error, l10n)),
          data: (value) => AttendanceHistoryList(history: value),
        ),
      ],
    );
  }
}

String _panelPeriod(AppLocalizations l10n, String period) {
  return switch (period) {
    'month' => l10n.periodMonth,
    'year' => l10n.periodYear,
    _ => l10n.periodWeek,
  };
}

String _panelDate() {
  final now = DateTime.now();
  final month = now.month.toString().padLeft(2, '0');
  final day = now.day.toString().padLeft(2, '0');
  return '${now.year}-$month-$day';
}
