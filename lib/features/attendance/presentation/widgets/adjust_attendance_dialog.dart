import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/utils/failure_messages.dart';
import 'package:teletech_drivers/features/attendance/data/providers/attendance_repository_provider.dart';

/// Drivers Admin correction. Reason is required. Times are Africa/Cairo wall clock.
class AdjustAttendanceDialog extends ConsumerStatefulWidget {
  const AdjustAttendanceDialog({required this.driverId, super.key});

  final String driverId;

  static Future<bool?> show(BuildContext context, {required String driverId}) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AdjustAttendanceDialog(driverId: driverId),
    );
  }

  @override
  ConsumerState<AdjustAttendanceDialog> createState() =>
      _AdjustAttendanceDialogState();
}

class _AdjustAttendanceDialogState
    extends ConsumerState<AdjustAttendanceDialog> {
  final _reason = TextEditingController();
  DateTime _day = DateTime.now();
  TimeOfDay _checkIn = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay? _checkOut;
  var _saving = false;
  String? _error;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final reason = _reason.text.trim();
    if (reason.isEmpty) {
      setState(() => _error = l10n.attendanceReasonRequired);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(attendanceRepositoryProvider)
          .adjust(
            driverId: widget.driverId,
            workDate: _date(_day),
            checkedInAt: _cairoUtc(_day, _checkIn),
            checkedOutAt: _checkOut == null
                ? null
                : _cairoUtc(_day, _checkOut!),
            reason: reason,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = messageForError(error, l10n);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.attendanceAdjustTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.attendanceWorkDate),
              subtitle: Text(_date(_day)),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _day,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _day = picked);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.attendanceCheckInTime),
              subtitle: Text(_checkIn.format(context)),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _checkIn,
                );
                if (picked != null) setState(() => _checkIn = picked);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.attendanceCheckOutTime),
              subtitle: Text(
                _checkOut == null
                    ? l10n.attendanceNoCheckOut
                    : _checkOut!.format(context),
              ),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime:
                      _checkOut ?? const TimeOfDay(hour: 17, minute: 0),
                );
                if (picked != null) setState(() => _checkOut = picked);
              },
            ),
            TextField(
              controller: _reason,
              decoration: InputDecoration(
                labelText: l10n.attendanceReasonLabel,
              ),
              maxLines: 2,
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.attendanceCancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(l10n.attendanceAdjustSave),
        ),
      ],
    );
  }
}

String _date(DateTime day) {
  final month = day.month.toString().padLeft(2, '0');
  final date = day.day.toString().padLeft(2, '0');
  return '${day.year}-$month-$date';
}

/// Africa/Cairo is UTC+2 year round.
DateTime _cairoUtc(DateTime day, TimeOfDay time) {
  return DateTime.utc(day.year, day.month, day.day, time.hour - 2, time.minute);
}
