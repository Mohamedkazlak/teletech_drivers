import 'package:teletech_drivers/features/attendance/domain/entities/attendance_day.dart';
import 'package:teletech_drivers/features/attendance/domain/entities/attendance_summary.dart';
import 'package:teletech_drivers/features/attendance/domain/entities/attendance_today.dart';

abstract interface class AttendanceRemoteDataSource {
  Future<AttendanceToday> today();

  Future<AttendanceHistory> history({
    required String path,
    required String period,
    String? date,
    String? driverId,
    String? status,
  });

  Future<AttendanceSummary> todaySummary();

  Future<AttendanceQrCode> qr();

  Future<void> scan({
    required String path,
    required String qrPayload,
    required double lat,
    required double lng,
    required double accuracyM,
    required bool isMocked,
  });

  Future<void> adjust(Map<String, dynamic> body);
}
