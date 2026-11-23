import 'package:teletech_drivers/features/attendance/domain/entities/attendance_day.dart';
import 'package:teletech_drivers/features/attendance/domain/entities/attendance_summary.dart';
import 'package:teletech_drivers/features/attendance/domain/entities/attendance_today.dart';
import 'package:teletech_drivers/features/attendance/domain/services/attendance_scan_flow.dart';

abstract interface class AttendanceRepository {
  Future<AttendanceToday> today();

  Future<AttendanceHistory> mine({required String period, String? date});

  Future<AttendanceHistory> driverHistory({
    required String driverId,
    required String period,
    String? date,
  });

  Future<AttendanceSummary> todaySummary();

  Future<AttendanceQrCode> qr();

  Future<void> checkIn({required AttendanceFix fix, required String qrPayload});

  Future<void> checkOut({
    required AttendanceFix fix,
    required String qrPayload,
  });

  Future<void> adjust({
    required String driverId,
    required String workDate,
    required DateTime checkedInAt,
    DateTime? checkedOutAt,
    required String reason,
  });
}
