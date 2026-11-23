import 'package:equatable/equatable.dart';
import 'package:teletech_drivers/features/attendance/domain/entities/attendance_day.dart';

class AttendanceSummary extends Equatable {
  const AttendanceSummary({
    required this.workDate,
    required this.offDay,
    required this.present,
    required this.checkedIn,
    required this.checkedOut,
    required this.absent,
  });

  final String workDate;
  final bool offDay;
  final List<AttendanceDay> present;
  final List<AttendanceDay> checkedIn;
  final List<AttendanceDay> checkedOut;
  final List<AttendanceDay> absent;

  @override
  List<Object?> get props => [workDate, offDay, present.length, absent.length];
}

class AttendanceQrCode extends Equatable {
  const AttendanceQrCode({
    required this.payload,
    required this.hqName,
    required this.version,
  });

  final String payload;
  final String hqName;
  final int version;

  @override
  List<Object?> get props => [payload, hqName, version];
}
