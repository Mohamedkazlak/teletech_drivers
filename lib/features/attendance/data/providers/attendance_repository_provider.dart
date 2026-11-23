import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/network/network_providers.dart';
import 'package:teletech_drivers/features/attendance/data/datasources/api_attendance_remote_data_source.dart';
import 'package:teletech_drivers/features/attendance/data/repositories/api_attendance_repository.dart';
import 'package:teletech_drivers/features/attendance/domain/repositories/attendance_repository.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return ApiAttendanceRepository(
    dataSource: ApiAttendanceRemoteDataSource(
      apiClient: ref.watch(apiClientProvider),
    ),
    failureMapper: ref.watch(apiFailureMapperProvider),
  );
});
