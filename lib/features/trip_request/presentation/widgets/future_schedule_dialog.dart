import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/time/cairo_clock.dart';
import 'package:teletech_drivers/features/trip_request/presentation/scheduling/future_schedule.dart';

/// Material date picker, then a 12-hour clock with AM and PM.
///
/// Hours that have already passed on the chosen day are left off the dial.
abstract final class FutureScheduleDialog {
  static Future<DateTime?> pick(
    BuildContext context, {
    DateTime? initialUtc,
    String? errorText,
    DateTime Function()? now,
  }) async {
    final l10n = AppLocalizations.of(context);
    final schedule = FutureSchedule(now: now);
    final slot = _initialWall(schedule, initialUtc);
    final first = schedule.earliestDay();
    final last = first.add(const Duration(days: 365));
    final initialDay = DateTime(slot.year, slot.month, slot.day);
    final day = await showDatePicker(
      context: context,
      initialDate: initialDay.isBefore(first) ? first : initialDay,
      firstDate: first,
      lastDate: last,
      helpText: errorText ?? l10n.selectDate,
      initialEntryMode: DatePickerEntryMode.calendar,
    );
    if (day == null || !context.mounted) return null;

    final selectedDay = DateTime(day.year, day.month, day.day);
    final initial =
        schedule.isMinuteSelectable(selectedDay, slot.hour, slot.minute)
        ? (hour: slot.hour, minute: slot.minute)
        : _firstSelectable(schedule, selectedDay);
    final time = await showDialog<_ClockTime>(
      context: context,
      builder: (context) => _ScheduleClockDialog(
        day: selectedDay,
        schedule: schedule,
        hour: initial.hour,
        minute: initial.minute,
        errorText: errorText,
      ),
    );
    if (time == null) return null;
    return CairoClock.toUtc(
      DateTime(
        selectedDay.year,
        selectedDay.month,
        selectedDay.day,
        time.hour,
        time.minute,
      ),
    );
  }
}

DateTime _initialWall(FutureSchedule schedule, DateTime? initialUtc) {
  if (initialUtc != null) {
    final wall = CairoClock.wall(initialUtc);
    final day = DateTime(wall.year, wall.month, wall.day);
    if (schedule.isMinuteSelectable(day, wall.hour, wall.minute)) return wall;
  }
  return schedule.nextSlot();
}

_ClockTime _firstSelectable(FutureSchedule schedule, DateTime day) {
  for (var hour = 0; hour < 24; hour++) {
    if (!schedule.hourHasSelectableMinute(day, hour)) continue;
    for (var minute = 0; minute < 60; minute++) {
      if (schedule.isMinuteSelectable(day, hour, minute)) {
        return (hour: hour, minute: minute);
      }
    }
  }
  return (hour: 0, minute: 0);
}

typedef _ClockTime = ({int hour, int minute});

/// 12-hour clock shown after the date is chosen. Past hours are not built.
class _ScheduleClockDialog extends StatefulWidget {
  const _ScheduleClockDialog({
    required this.day,
    required this.schedule,
    required this.hour,
    required this.minute,
    this.errorText,
  });

  final DateTime day;
  final FutureSchedule schedule;
  final int hour;
  final int minute;
  final String? errorText;

  @override
  State<_ScheduleClockDialog> createState() => _ScheduleClockDialogState();
}

class _ScheduleClockDialogState extends State<_ScheduleClockDialog> {
  late int _hour;
  late int _minute;
  var _pickingHour = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _hour = widget.hour;
    _minute = widget.minute;
    _error = widget.errorText;
  }

  List<int> get _hours {
    return [
      for (var hour = 0; hour < 24; hour++)
        if (widget.schedule.hourHasSelectableMinute(widget.day, hour)) hour,
    ];
  }

  List<int> get _minutes {
    return [
      for (var minute = 0; minute < 60; minute++)
        if (widget.schedule.isMinuteSelectable(widget.day, _hour, minute))
          minute,
    ];
  }

  List<int> _faceHours() {
    final period = _periodOf(_hour);
    return [
      for (final hour in _hours)
        if (_periodOf(hour) == period) hour,
    ];
  }

  List<int> _minuteMarks() {
    final marks = [
      for (final minute in _minutes)
        if (minute % 5 == 0) minute,
    ];
    return marks.isEmpty ? _minutes : marks;
  }

  void _snapMinute() {
    if (widget.schedule.isMinuteSelectable(widget.day, _hour, _minute)) return;
    for (final minute in _minutes) {
      _minute = minute;
      return;
    }
  }

  void _selectHour(int hour) {
    setState(() {
      _hour = hour;
      _error = null;
      _snapMinute();
      _pickingHour = false;
    });
  }

  void _selectMinute(int minute) {
    if (!widget.schedule.isMinuteSelectable(widget.day, _hour, minute)) return;
    setState(() {
      _minute = minute;
      _error = null;
    });
  }

  void _selectPeriod(DayPeriod period) {
    if (_periodOf(_hour) == period) {
      setState(() => _pickingHour = true);
      return;
    }
    final hours = [
      for (final hour in _hours)
        if (_periodOf(hour) == period) hour,
    ];
    if (hours.isEmpty) return;
    setState(() {
      _hour = hours.first;
      _error = null;
      _snapMinute();
      _pickingHour = true;
    });
  }

  void _drag(Offset local) {
    final delta = local - _ClockLayout.center;
    if (delta.distance < 8) return;
    if (_pickingHour) {
      final hour = _nearestHour(delta);
      if (hour == null || hour == _hour) return;
      setState(() {
        _hour = hour;
        _error = null;
        _snapMinute();
      });
      return;
    }
    final minute = _nearestMinute(delta);
    if (minute == null || minute == _minute) return;
    setState(() {
      _minute = minute;
      _error = null;
    });
  }

  int? _nearestHour(Offset delta) {
    final hours = _faceHours();
    if (hours.isEmpty) return null;
    final fraction = _ClockLayout.fraction(delta);
    final slot = (fraction * 12).round() % 12;
    return hours.reduce((best, hour) {
      final bestDistance = _circularDistance(best % 12, slot, 12);
      final distance = _circularDistance(hour % 12, slot, 12);
      return distance < bestDistance ? hour : best;
    });
  }

  int? _nearestMinute(Offset delta) {
    final minutes = _minutes;
    if (minutes.isEmpty) return null;
    final slot = (_ClockLayout.fraction(delta) * 60).round() % 60;
    return minutes.reduce((best, minute) {
      final bestDistance = _circularDistance(best, slot, 60);
      final distance = _circularDistance(minute, slot, 60);
      return distance < bestDistance ? minute : best;
    });
  }

  void _confirm() {
    final l10n = AppLocalizations.of(context);
    if (!widget.schedule.isMinuteSelectable(widget.day, _hour, _minute)) {
      setState(() {
        _error = l10n.validationDateTimeFuture;
        _snapMinute();
      });
      return;
    }
    Navigator.of(context).pop((hour: _hour, minute: _minute));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final material = MaterialLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final error = _error;
    final time = TimeOfDay(hour: _hour, minute: _minute);
    final amOpen = _hours.any((hour) => _periodOf(hour) == DayPeriod.am);
    final pmOpen = _hours.any((hour) => _periodOf(hour) == DayPeriod.pm);

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (error != null) ...[
              Text(
                error,
                key: const Key('schedule-error'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.error,
                ),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              l10n.selectTime,
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 80,
              child: Row(
                children: [
                  Expanded(
                    child: _TimeBox(
                      key: const Key('schedule-hour'),
                      text: material.formatHour(
                        time,
                        alwaysUse24HourFormat: false,
                      ),
                      selected: _pickingHour,
                      onTap: () => setState(() => _pickingHour = true),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(':', style: theme.textTheme.displaySmall),
                  ),
                  Expanded(
                    child: _TimeBox(
                      key: const Key('schedule-minute'),
                      text: material.formatMinute(time),
                      selected: !_pickingHour,
                      onTap: () => setState(() => _pickingHour = false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _PeriodToggle(
                    amText: material.anteMeridiemAbbreviation,
                    pmText: material.postMeridiemAbbreviation,
                    amEnabled: amOpen,
                    pmEnabled: pmOpen,
                    period: _periodOf(_hour),
                    onChanged: _selectPeriod,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: _ClockFace(
                pickingHour: _pickingHour,
                use24Hour: false,
                hour: _hour,
                minute: _minute,
                hours: _faceHours(),
                minutes: _minuteMarks(),
                onHour: _selectHour,
                onMinute: _selectMinute,
                onDrag: _drag,
                onDragEnd: () {
                  if (_pickingHour) setState(() => _pickingHour = false);
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: Text(material.cancelButtonLabel),
                ),
                TextButton(
                  key: const Key('schedule-confirm'),
                  onPressed: _confirm,
                  child: Text(material.okButtonLabel),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

DayPeriod _periodOf(int hour) => hour < 12 ? DayPeriod.am : DayPeriod.pm;

int _circularDistance(int a, int b, int modulo) {
  final delta = (a - b).abs();
  return math.min(delta, modulo - delta);
}

/// Positions on the Material clock. Outer ring is 1–12, inner ring is 13–00.
abstract final class _ClockLayout {
  static const double dial = 256;
  static const double labelRadius = dial / 2 - 28;
  static const double innerRadius = labelRadius - 28;
  static const Offset center = Offset(dial / 2, dial / 2);

  static Offset offset({
    required int slot,
    required int divisions,
    required bool inner,
  }) {
    final fraction = (slot % divisions) / divisions;
    final theta = math.pi / 2 - fraction * 2 * math.pi;
    final radius = inner ? innerRadius : labelRadius;
    return center + Offset(radius * math.cos(theta), -radius * math.sin(theta));
  }

  static double fraction(Offset delta) {
    final theta = math.atan2(-delta.dy, delta.dx);
    final turns = ((math.pi / 2 - theta) / (2 * math.pi)) % 1;
    return turns < 0 ? turns + 1 : turns;
  }
}

class _ClockFace extends StatelessWidget {
  const _ClockFace({
    required this.pickingHour,
    required this.use24Hour,
    required this.hour,
    required this.minute,
    required this.hours,
    required this.minutes,
    required this.onHour,
    required this.onMinute,
    required this.onDrag,
    required this.onDragEnd,
  });

  final bool pickingHour;
  final bool use24Hour;
  final int hour;
  final int minute;
  final List<int> hours;
  final List<int> minutes;
  final ValueChanged<int> onHour;
  final ValueChanged<int> onMinute;
  final ValueChanged<Offset> onDrag;
  final VoidCallback onDragEnd;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final material = MaterialLocalizations.of(context);
    final hand = pickingHour
        ? _ClockLayout.offset(
            slot: hour % 12,
            divisions: 12,
            inner: use24Hour && hour >= 12,
          )
        : _ClockLayout.offset(slot: minute, divisions: 60, inner: false);

    return GestureDetector(
      onPanUpdate: (details) => onDrag(details.localPosition),
      onPanEnd: (_) => onDragEnd(),
      child: SizedBox(
        width: _ClockLayout.dial,
        height: _ClockLayout.dial,
        child: Stack(
          children: [
            CustomPaint(
              size: const Size.square(_ClockLayout.dial),
              painter: _HandPainter(
                target: hand,
                background: scheme.surfaceContainerHighest,
                hand: scheme.primary,
              ),
            ),
            if (pickingHour)
              for (final value in hours)
                _faceLabel(
                  context,
                  key: ValueKey('schedule-hour-$value'),
                  text: _hourFaceText(material, value),
                  offset: _ClockLayout.offset(
                    slot: value % 12,
                    divisions: 12,
                    inner: use24Hour && value >= 12,
                  ),
                  selected: value == hour,
                  onTap: () => onHour(value),
                )
            else
              for (final value in minutes)
                _faceLabel(
                  context,
                  key: ValueKey('schedule-minute-$value'),
                  text: material.formatMinute(
                    TimeOfDay(hour: 0, minute: value),
                  ),
                  offset: _ClockLayout.offset(
                    slot: value,
                    divisions: 60,
                    inner: false,
                  ),
                  selected: value == minute,
                  onTap: () => onMinute(value),
                ),
          ],
        ),
      ),
    );
  }

  String _hourFaceText(MaterialLocalizations material, int value) {
    if (!use24Hour) {
      return material.formatHour(
        TimeOfDay(hour: value, minute: 0),
        alwaysUse24HourFormat: false,
      );
    }
    if (value == 0) {
      return material.formatHour(
        const TimeOfDay(hour: 0, minute: 0),
        alwaysUse24HourFormat: true,
      );
    }
    return material.formatDecimal(value);
  }

  Widget _faceLabel(
    BuildContext context, {
    required Key key,
    required String text,
    required Offset offset,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Positioned(
      left: offset.dx - 18,
      top: offset.dy - 18,
      width: 36,
      height: 36,
      child: InkWell(
        key: key,
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Center(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: selected ? scheme.onPrimary : scheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _HandPainter extends CustomPainter {
  const _HandPainter({
    required this.target,
    required this.background,
    required this.hand,
  });

  final Offset target;
  final Color background;
  final Color hand;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    canvas.drawCircle(
      center,
      size.shortestSide / 2,
      Paint()..color = background,
    );
    final paint = Paint()
      ..color = hand
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, 4, paint);
    canvas.drawLine(center, target, paint);
    canvas.drawCircle(target, 24, paint);
  }

  @override
  bool shouldRepaint(_HandPainter oldDelegate) {
    return oldDelegate.target != target ||
        oldDelegate.background != background ||
        oldDelegate.hand != hand;
  }
}

class _TimeBox extends StatelessWidget {
  const _TimeBox({
    required this.text,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(context).textTheme.displayLarge?.copyWith(
      color: selected ? scheme.onPrimaryContainer : scheme.onSurface,
    );
    return Material(
      color: selected
          ? scheme.primaryContainer
          : scheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(text, style: style),
          ),
        ),
      ),
    );
  }
}

class _PeriodToggle extends StatelessWidget {
  const _PeriodToggle({
    required this.amText,
    required this.pmText,
    required this.amEnabled,
    required this.pmEnabled,
    required this.period,
    required this.onChanged,
  });

  final String amText;
  final String pmText;
  final bool amEnabled;
  final bool pmEnabled;
  final DayPeriod period;
  final ValueChanged<DayPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      child: Column(
        children: [
          Expanded(
            child: _PeriodButton(
              key: const Key('schedule-period-am'),
              text: amText,
              selected: period == DayPeriod.am,
              enabled: amEnabled,
              onTap: () => onChanged(DayPeriod.am),
            ),
          ),
          Expanded(
            child: _PeriodButton(
              key: const Key('schedule-period-pm'),
              text: pmText,
              selected: period == DayPeriod.pm,
              enabled: pmEnabled,
              onTap: () => onChanged(DayPeriod.pm),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodButton extends StatelessWidget {
  const _PeriodButton({
    required this.text,
    required this.selected,
    required this.enabled,
    required this.onTap,
    super.key,
  });

  final String text;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final active = enabled && selected;
    return Material(
      color: active ? scheme.tertiaryContainer : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: enabled ? scheme.outline : scheme.outlineVariant,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Center(
          child: Text(
            text,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: active
                  ? scheme.onTertiaryContainer
                  : scheme.onSurfaceVariant.withValues(
                      alpha: enabled ? 1 : 0.38,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
