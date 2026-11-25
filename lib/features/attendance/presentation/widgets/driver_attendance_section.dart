import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/presentation/app_loading_indicator.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/core/theme/app_gradients.dart';
import 'package:teletech_drivers/core/theme/app_motion.dart';
import 'package:teletech_drivers/core/theme/app_theme.dart';
import 'package:teletech_drivers/core/theme/app_typography.dart';
import 'package:teletech_drivers/core/widgets/slide_to_confirm.dart';
import 'package:teletech_drivers/core/widgets/success_moment.dart';
import 'package:teletech_drivers/core/widgets/animation_helpers.dart';
import 'package:teletech_drivers/core/widgets/brand_mark.dart';
import 'package:teletech_drivers/core/widgets/segmented_switch.dart';
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

  /// Bumped on every successful scan; replays the ring burst.
  var _successCount = 0;

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
    if (result.step == AttendanceScanStep.success) {
      setState(() => _successCount++);
      unawaited(showSuccessMoment(context, message: message));
      ref.invalidate(attendanceTodayProvider);
      ref.invalidate(myAttendanceProvider);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
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
          padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 0),
          child: AnimatedSize(
            duration: AppAnimations.duration(context, AppMotion.standard),
            curve: AppMotion.easeOut,
            alignment: AlignmentDirectional.topStart,
            child: today.when(
              skipLoadingOnRefresh: true,
              skipLoadingOnReload: true,
              loading: () => const _StatusCardSkeleton(),
              error: (error, _) => _StatusCardShell(
                child: Text(
                  messageForError(error, l10n),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.white,
                  ),
                ),
              ),
              data: (value) => _StatusCard(
                today: value,
                scanning: _scanning,
                successCount: _successCount,
                onScan: () => _scan(value),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SegmentedSwitch<String>(
            options: [
              for (final period in const ['week', 'month', 'year'])
                SegmentOption(
                  value: period,
                  label: _periodLabel(l10n, period),
                ),
            ],
            selected: _period,
            onChanged: (value) => setState(() => _period = value),
          ),
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: AppAnimations.duration(context, AppMotion.quick),
          switchInCurve: AppMotion.easeOut,
          switchOutCurve: AppMotion.easeOut,
          child: history.when(
            loading: () => Center(
              key: const ValueKey('loading'),
              child: AppLoadingIndicator(label: l10n.loading),
            ),
            error: (error, _) => Padding(
              key: const ValueKey('error'),
              padding: const EdgeInsets.all(16),
              child: Text(messageForError(error, l10n)),
            ),
            data: (value) => Padding(
              key: ValueKey('history-$_period'),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AttendanceHistoryList(history: value),
            ),
          ),
        ),
      ],
    );
  }
}

/// Dark hero surface shared by the status card and its loading/error states.
class _StatusCardShell extends StatelessWidget {
  const _StatusCardShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.floatingShadow(opacity: 0.18),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Positioned.fill(child: RingField()),
          Padding(padding: const EdgeInsets.all(20), child: child),
        ],
      ),
    );
  }
}

class _StatusCardSkeleton extends StatelessWidget {
  const _StatusCardSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget bars = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _bar(width: 96, height: 12),
        const SizedBox(height: 28),
        _bar(width: 200, height: 24),
        const SizedBox(height: 28),
        _bar(height: AppTheme.controlHeight, radius: AppTheme.controlRadius),
      ],
    );
    if (!AppAnimations.disabled(context)) {
      bars = bars
          .animate(onPlay: (c) => c.repeat())
          .shimmer(
            duration: const Duration(milliseconds: 1400),
            color: AppColors.white.withValues(alpha: 0.12),
          );
    }
    return _StatusCardShell(child: bars);
  }

  Widget _bar({double? width, double height = 14, double radius = 8}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.today,
    required this.scanning,
    required this.successCount,
    required this.onScan,
  });

  final AttendanceToday today;
  final bool scanning;
  final int successCount;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toString();
    final time = DateFormat.Hm(locale);
    final workDate = DateTime.tryParse(today.workDate);
    final (label, dot, icon) = switch (today.status) {
      'checked_in' => (
        l10n.attendanceCheckedInAt(
          today.checkedInAt == null
              ? '—'
              : time.format(today.checkedInAt!.toLocal()),
        ),
        AppColors.success,
        Icons.check_rounded,
      ),
      'checked_out' => (
        l10n.attendanceCheckedOutAt(
          today.checkedOutAt == null
              ? '—'
              : time.format(today.checkedOutAt!.toLocal()),
        ),
        AppColors.lightBlue,
        Icons.logout_rounded,
      ),
      _ => (
        l10n.attendanceNotCheckedIn,
        AppColors.warning,
        Icons.qr_code_2_rounded,
      ),
    };
    final canScan = !scanning && !today.isCheckedOut;
    final duration = AppAnimations.duration(context, AppMotion.standard);

    return _StatusCardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.attendanceCardTitle,
                  style: textTheme.labelLarge?.copyWith(
                    color: AppColors.white.withValues(alpha: 0.72),
                  ),
                ),
              ),
              if (workDate != null)
                Text(
                  DateFormat.MMMEd(locale).format(workDate),
                  style: AppTypography.tabular(
                    textTheme.labelLarge?.copyWith(
                      color: AppColors.white.withValues(alpha: 0.72),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              RingBurst(
                trigger: successCount == 0 ? null : successCount,
                color: AppColors.white,
                child: RingPulse(
                  size: 64,
                  color: AppColors.signal,
                  active: today.isCheckedIn,
                  child: AnimatedContainer(
                    duration: duration,
                    curve: AppMotion.easeOut,
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: today.isCheckedIn
                          ? AppColors.signal
                          : AppColors.white.withValues(alpha: 0.12),
                      border: Border.all(
                        color: AppColors.white.withValues(alpha: 0.24),
                      ),
                    ),
                    child: AnimatedSwitcher(
                      duration: duration,
                      transitionBuilder: (child, animation) => ScaleTransition(
                        scale: Tween<double>(
                          begin: 0.7,
                          end: 1,
                        ).animate(animation),
                        child: FadeTransition(opacity: animation, child: child),
                      ),
                      child: Icon(
                        icon,
                        key: ValueKey(icon),
                        color: AppColors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AnimatedContainer(
                          duration: duration,
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: dot,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: AnimatedSwitcher(
                            duration: duration,
                            switchInCurve: AppMotion.easeOut,
                            switchOutCurve: AppMotion.easeOut,
                            layoutBuilder: (current, previous) => Stack(
                              alignment: AlignmentDirectional.centerStart,
                              children: [...previous, ?current],
                            ),
                            child: Text(
                              label,
                              key: ValueKey(label),
                              style: AppTypography.tabular(
                                textTheme.titleLarge?.copyWith(
                                  color: AppColors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SlideToConfirm(
            label: today.isCheckedIn
                ? l10n.slideToCheckOut
                : l10n.slideToCheckIn,
            icon: Icons.arrow_forward_rounded,
            isLoading: scanning,
            enabled: canScan,
            doneLabel: l10n.attendanceStatusCheckedOut,
            onConfirmed: onScan,
          ),
        ],
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
    final textTheme = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toString();
    final time = DateFormat.Hm(locale);
    final dayFormat = DateFormat.MMMEd(locale);
    if (history.days.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Text(
          l10n.attendanceHistoryEmpty,
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(color: AppColors.inkMuted),
        ),
      );
    }
    final animate = !AppAnimations.disabled(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(4, 4, 4, 10),
          child: Text(
            l10n.attendanceTotals(
              history.totals.daysPresent,
              history.totals.daysAbsent,
              history.totals.totalOnSiteHours.toStringAsFixed(1),
            ),
            style: AppTypography.tabular(
              textTheme.labelLarge?.copyWith(color: AppColors.inkMuted),
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            border: Border.all(color: AppColors.line),
          ),
          child: Column(
            children: [
              for (var i = 0; i < history.days.length; i++) ...[
                if (i > 0)
                  const Divider(indent: 16, endIndent: 16),
                _maybeAnimate(
                  animate && i < 8,
                  i,
                  _DayRow(
                    date: _formatDay(history.days[i].workDate, dayFormat),
                    line: _line(l10n, history.days[i], time),
                    status: StatusChip(
                      label: _statusLabel(l10n, history.days[i].status),
                      color: history.days[i].isAbsent
                          ? AppColors.warning
                          : AppColors.success,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _maybeAnimate(bool animate, int index, Widget child) {
    if (!animate) return child;
    final delay = AppMotion.staggerAt(index);
    return child
        .animate()
        .fadeIn(delay: delay, duration: AppMotion.standard)
        .moveY(
          begin: 6,
          end: 0,
          delay: delay,
          duration: AppMotion.standard,
          curve: AppMotion.easeOut,
        );
  }

  String _formatDay(String workDate, DateFormat format) {
    final parsed = DateTime.tryParse(workDate);
    return parsed == null ? workDate : format.format(parsed);
  }

  String _line(AppLocalizations l10n, AttendanceDay day, DateFormat time) {
    // The status chip already says "Absent"; no second line.
    if (day.isAbsent) return '';
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

class _DayRow extends StatelessWidget {
  const _DayRow({required this.date, required this.line, required this.status});

  final String date;
  final String line;
  final Widget status;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(date, style: textTheme.titleSmall),
                if (line.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    line,
                    style: AppTypography.tabular(
                      textTheme.bodySmall?.copyWith(color: AppColors.inkMuted),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          status,
        ],
      ),
    );
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
