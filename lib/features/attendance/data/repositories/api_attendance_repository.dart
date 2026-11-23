import 'package:teletech_drivers/core/constants/api_paths.dart';
import 'package:teletech_drivers/core/errors/failures.dart';
import 'package:teletech_drivers/core/network/api_exception.dart';
import 'package:teletech_drivers/core/network/api_failure_mapper.dart';
import 'package:teletech_drivers/features/attendance/data/datasources/attendance_remote_data_source.dart';
import 'package:teletech_drivers/features/attendance/domain/entities/attendance_day.dart';
import 'package:teletech_drivers/features/attendance/domain/entities/attendance_summary.dart';
import 'package:teletech_drivers/features/attendance/domain/entities/attendance_today.dart';
import 'package:teletech_drivers/features/attendance/domain/repositories/attendance_repository.dart';
import 'package:teletech_drivers/features/attendance/domain/services/attendance_scan_flow.dart';

class ApiAttendanceRepository implements AttendanceRepository {
  const ApiAttendanceRepository({
    required this.dataSource,
    this.failureMapper = const ApiFailureMapper(),
  });

  final AttendanceRemoteDataSource dataSource;
  final ApiFailureMapper failureMapper;

  @override
  Future<AttendanceToday> today() => _guard(dataSource.today);

  @override
  Future<AttendanceHistory> mine({required String period, String? date}) {
    return _guard(
      () => dataSource.history(
        path: ApiPaths.attendanceMe,
        period: period,
        date: date,
      ),
    );
  }

  @override
  Future<AttendanceHistory> driverHistory({
    required String driverId,
    required String period,
    String? date,
  }) {
    return _guard(
      () => dataSource.history(
        path: ApiPaths.driverAttendance(driverId),
        period: period,
        date: date,
      ),
    );
  }

  @override
  Future<AttendanceSummary> todaySummary() => _guard(dataSource.todaySummary);

  @override
  Future<AttendanceQrCode> qr() => _guard(dataSource.qr);

  @override
  Future<void> checkIn({
    required AttendanceFix fix,
    required String qrPayload,
  }) {
    return _guard(
      () => dataSource.scan(
        path: ApiPaths.attendanceCheckIn,
        qrPayload: qrPayload,
        lat: fix.lat,
        lng: fix.lng,
        accuracyM: fix.accuracyM,
        isMocked: fix.isMocked,
      ),
    );
  }

  @override
  Future<void> checkOut({
    required AttendanceFix fix,
    required String qrPayload,
  }) {
    return _guard(
      () => dataSource.scan(
        path: ApiPaths.attendanceCheckOut,
        qrPayload: qrPayload,
        lat: fix.lat,
        lng: fix.lng,
        accuracyM: fix.accuracyM,
        isMocked: fix.isMocked,
      ),
    );
  }

  @override
  Future<void> adjust({
    required String driverId,
    required String workDate,
    required DateTime checkedInAt,
    DateTime? checkedOutAt,
    required String reason,
  }) {
    return _guard(
      () => dataSource.adjust({
        'driver_id': driverId,
        'work_date': workDate,
        'checked_in_at': checkedInAt.toUtc().toIso8601String(),
        if (checkedOutAt != null)
          'checked_out_at': checkedOutAt.toUtc().toIso8601String(),
        'reason': reason,
      }),
    );
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(_map(error), stackTrace);
    }
  }

  Failure _map(Object error) {
    final code = switch (error) {
      ConflictApiException(:final code) => code,
      ValidationApiException(:final code) => code,
      _ => null,
    };
    if (code != null && code.isNotEmpty) {
      final distance = switch (error) {
        ConflictApiException(:final distanceM) => distanceM,
        ValidationApiException(:final distanceM) => distanceM,
        _ => null,
      };
      final radius = switch (error) {
        ConflictApiException(:final radiusM) => radiusM,
        ValidationApiException(:final radiusM) => radiusM,
        _ => null,
      };
      return AttendanceFailure(
        code: code,
        distanceM: distance,
        radiusM: radius,
      );
    }
    return failureMapper.map(error);
  }
}
