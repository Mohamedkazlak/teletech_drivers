import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/features/attendance/data/providers/attendance_repository_provider.dart';
import 'package:teletech_drivers/features/attendance/domain/entities/attendance_day.dart';
import 'package:teletech_drivers/features/attendance/domain/entities/attendance_summary.dart';
import 'package:teletech_drivers/features/attendance/domain/entities/attendance_today.dart';

final attendanceTodayProvider = FutureProvider.autoDispose<AttendanceToday>((
  ref,
) {
  return ref.watch(attendanceRepositoryProvider).today();
});

final myAttendanceProvider = FutureProvider.autoDispose
    .family<AttendanceHistory, ({String period, String? date})>((ref, query) {
      return ref
          .watch(attendanceRepositoryProvider)
          .mine(period: query.period, date: query.date);
    });

final driverAttendanceProvider = FutureProvider.autoDispose
    .family<
      AttendanceHistory,
      ({String driverId, String period, String? date})
    >((ref, query) {
      return ref
          .watch(attendanceRepositoryProvider)
          .driverHistory(
            driverId: query.driverId,
            period: query.period,
            date: query.date,
          );
    });

final attendanceSummaryProvider = FutureProvider.autoDispose<AttendanceSummary>(
  (ref) {
    return ref.watch(attendanceRepositoryProvider).todaySummary();
  },
);

final attendanceQrProvider = FutureProvider.autoDispose<AttendanceQrCode>((
  ref,
) {
  return ref.watch(attendanceRepositoryProvider).qr();
});
