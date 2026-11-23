import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/presentation/app_loading_indicator.dart';
import 'package:teletech_drivers/core/router/app_routes.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/core/utils/failure_messages.dart';
import 'package:teletech_drivers/core/widgets/app_scaffold.dart';
import 'package:teletech_drivers/features/attendance/domain/entities/attendance_day.dart';
import 'package:teletech_drivers/features/attendance/presentation/providers/attendance_providers.dart';

/// Today's present, checked-in, checked-out, and absent drivers.
class AttendanceTodayScreen extends ConsumerWidget {
  const AttendanceTodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final summary = ref.watch(attendanceSummaryProvider);
    return AppScaffold(
      title: l10n.navAttendance,
      actions: [
        IconButton(
          tooltip: l10n.attendanceQrTitle,
          onPressed: () => context.push(AppRoutes.driversAdminAttendanceQr),
          icon: const Icon(Icons.qr_code_2),
        ),
      ],
      body: summary.when(
        loading: () => Center(child: AppLoadingIndicator(label: l10n.loading)),
        error: (error, _) => Center(child: Text(messageForError(error, l10n))),
        data: (value) {
          if (value.offDay) {
            return Center(child: Text(l10n.attendanceOffDay));
          }
          return ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              _Group(
                title: l10n.attendanceStatusCheckedIn,
                count: value.checkedIn.length,
                color: AppColors.success,
                rows: value.checkedIn,
              ),
              _Group(
                title: l10n.attendanceStatusCheckedOut,
                count: value.checkedOut.length,
                color: AppColors.midBlue,
                rows: value.checkedOut,
              ),
              _Group(
                title: l10n.attendanceAbsent,
                count: value.absent.length,
                color: AppColors.warning,
                rows: value.absent,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({
    required this.title,
    required this.count,
    required this.color,
    required this.rows,
  });

  final String title;
  final int count;
  final Color color;
  final List<AttendanceDay> rows;

  @override
  Widget build(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          title: Text(title, style: TextStyle(color: color)),
          trailing: Text('$count'),
        ),
        if (rows.isEmpty)
          const SizedBox.shrink()
        else
          for (final row in rows)
            ListTile(
              dense: true,
              title: Text(row.localizedName(language)),
              onTap: () => context.push(
                AppRoutes.driversAdminDriverDetailsPath(row.driverId),
              ),
            ),
      ],
    );
  }
}
