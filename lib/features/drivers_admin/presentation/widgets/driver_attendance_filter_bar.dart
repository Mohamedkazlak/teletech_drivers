import 'package:flutter/material.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/features/drivers_admin/domain/entities/driver_attendance_filter.dart';

/// Filter: All / Checked in today / Not checked in.
class DriverAttendanceFilterBar extends StatelessWidget {
  const DriverAttendanceFilterBar({
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final DriverAttendanceFilter? selected;
  final ValueChanged<DriverAttendanceFilter?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 4),
      child: Row(
        children: [
          FilterChip(
            label: Text(l10n.attendanceFilterAll),
            selected: selected == null,
            onSelected: (_) => onChanged(null),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: Text(l10n.attendanceFilterCheckedIn),
            selected: selected == DriverAttendanceFilter.checkedIn,
            onSelected: (_) => onChanged(DriverAttendanceFilter.checkedIn),
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: Text(l10n.attendanceFilterNotCheckedIn),
            selected: selected == DriverAttendanceFilter.notCheckedIn,
            onSelected: (_) => onChanged(DriverAttendanceFilter.notCheckedIn),
          ),
        ],
      ),
    );
  }
}
