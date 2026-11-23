import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/presentation/app_loading_indicator.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/core/utils/failure_messages.dart';
import 'package:teletech_drivers/core/widgets/status_chip.dart';
import 'package:teletech_drivers/features/attendance/data/services/geolocator_attendance_locator.dart';
import 'package:teletech_drivers/features/attendance/domain/entities/attendance_day.dart';
import 'package:teletech_drivers/features/attendance/domain/entities/attendance_today.dart';
import 'package:teletech_drivers/features/attendance/domain/services/attendance_scan_flow.dart';
import 'package:teletech_drivers/features/attendance/presentation/providers/attendance_providers.dart';
import 'package:teletech_drivers/features/attendance/presentation/screens/attendance_scan_screen.dart';
import 'package:teletech_drivers/features/attendance/data/providers/attendance_repository_provider.dart';
import 'package:teletech_drivers/features/attendance/presentation/utils/attendance_error_message.dart';

/// Status card, one scan button, and week/month/year history.
class DriverAttendanceSection extends ConsumerStatefulWidget {
  const DriverAttendanceSection({super.key});

  @override
  ConsumerState<DriverAttendanceSection> createState() =>
      _DriverAttendanceSectionState();
}

class _DriverAttendanceSectionState
    extends ConsumerState<DriverAttendanceSection> {
  var _period = 'week';
  var _scanning = false;

  Future<void> _scan(AttendanceToday today) async {
    if (_scanning) return;
    setState(() => _scanning = true);
    final l10n = AppLocalizations.of(context);
    final repository = ref.read(attendanceRepositoryProvider);
    final result = await const AttendanceScanFlow().run(
      locate: const GeolocatorAttendanceLocator().locate,
      scan: () => AttendanceScanScreen.open(context),
      submit: (fix, payload) {
        if (today.isCheckedIn) {
          return repository.checkOut(fix: fix, qrPayload: payload);
        }
        return repository.checkIn(fix: fix, qrPayload: payload);
      },
    );
    if (!mounted) return;
    setState(() => _scanning = false);
    final message = switch (result.step) {
      AttendanceScanStep.permissionDenied =>
        l10n.locationPermissionDeniedMessage,
      AttendanceScanStep.gpsOff => l10n.locationServicesDisabledMessage,
      AttendanceScanStep.cancelled => l10n.attendanceScanCancelled,
      AttendanceScanStep.success =>
        today.isCheckedIn
            ? l10n.attendanceCheckedOutSuccess
            : l10n.attendanceCheckedInSuccess,
      AttendanceScanStep.failed => attendanceErrorMessage(
        l10n,
        code: result.code ?? '',
        distanceM: result.distanceM,
        radiusM: result.radiusM,
      ),
    };
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
    if (result.step == AttendanceScanStep.success) {
      ref.invalidate(attendanceTodayProvider);
      ref.invalidate(myAttendanceProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final today = ref.watch(attendanceTodayProvider);
    final history = ref.watch(
      myAttendanceProvider((period: _period, date: _todayDate())),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 0),
          child: today.when(
            loading: () => AppLoadingIndicator(label: l10n.loading),
            error: (error, _) => Text(messageForError(error, l10n)),
            data: (value) => _StatusCard(
              today: value,
              scanning: _scanning,
              onScan: () => _scan(value),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            children: [
              for (final period in const ['week', 'month', 'year'])
                ChoiceChip(
                  label: Text(_periodLabel(l10n, period)),
                  selected: _period == period,
                  onSelected: (_) => setState(() => _period = period),
                ),
            ],
          ),
        ),
        history.when(
          loading: () => AppLoadingIndicator(label: l10n.loading),
          error: (error, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: Text(messageForError(error, l10n)),
          ),
          data: (value) => AttendanceHistoryList(history: value),
        ),
      ],
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.today,
    required this.scanning,
    required this.onScan,
  });

  final AttendanceToday today;
  final bool scanning;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final time = DateFormat.Hm(locale);
    final (label, color) = switch (today.status) {
      'checked_in' => (
        l10n.attendanceCheckedInAt(
          today.checkedInAt == null
              ? '—'
              : time.format(today.checkedInAt!.toLocal()),
        ),
        AppColors.success,
      ),
      'checked_out' => (
        l10n.attendanceCheckedOutAt(
          today.checkedOutAt == null
              ? '—'
              : time.format(today.checkedOutAt!.toLocal()),
        ),
        AppColors.midBlue,
      ),
      _ => (l10n.attendanceNotCheckedIn, AppColors.warning),
    };
    final button = today.isCheckedIn
        ? l10n.attendanceScanCheckOut
        : l10n.attendanceScanCheckIn;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.attendanceCardTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            StatusChip(label: label, color: color),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: scanning || today.isCheckedOut ? null : onScan,
              icon: scanning
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.qr_code_scanner),
              label: Text(scanning ? l10n.loading : button),
            ),
          ],
        ),
      ),
    );
  }
}

class AttendanceHistoryList extends StatelessWidget {
  const AttendanceHistoryList({required this.history, super.key});

  final AttendanceHistory history;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final time = DateFormat.Hm(locale);
    if (history.days.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(l10n.attendanceHistoryEmpty, textAlign: TextAlign.center),
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Text(
            l10n.attendanceTotals(
              history.totals.daysPresent,
              history.totals.daysAbsent,
              history.totals.totalOnSiteHours.toStringAsFixed(1),
            ),
          ),
        ),
        for (final day in history.days)
          ListTile(
            title: Text(day.workDate),
            subtitle: Text(_line(l10n, day, time)),
            trailing: StatusChip(
              label: _statusLabel(l10n, day.status),
              color: day.isAbsent ? AppColors.warning : AppColors.success,
            ),
          ),
      ],
    );
  }

  String _line(AppLocalizations l10n, AttendanceDay day, DateFormat time) {
    if (day.isAbsent) return l10n.attendanceAbsent;
    final checkIn = day.checkedInAt == null
        ? '—'
        : time.format(day.checkedInAt!.toLocal());
    final checkOut = day.checkedOutAt == null
        ? l10n.attendanceNoCheckOut
        : time.format(day.checkedOutAt!.toLocal());
    final hours = day.onSiteHours == null
        ? '—'
        : day.onSiteHours!.toStringAsFixed(1);
    return l10n.attendanceDayLine(checkIn, checkOut, hours);
  }
}

String _statusLabel(AppLocalizations l10n, String status) {
  return switch (status) {
    'checked_in' => l10n.attendanceStatusCheckedIn,
    'checked_out' => l10n.attendanceStatusCheckedOut,
    'absent' => l10n.attendanceAbsent,
    _ => status,
  };
}

String _periodLabel(AppLocalizations l10n, String period) {
  return switch (period) {
    'month' => l10n.periodMonth,
    'year' => l10n.periodYear,
    _ => l10n.periodWeek,
  };
}

String _todayDate() {
  final now = DateTime.now();
  final month = now.month.toString().padLeft(2, '0');
  final day = now.day.toString().padLeft(2, '0');
  return '${now.year}-$month-$day';
}
