import 'package:teletech_drivers/core/constants/api_json_keys.dart';
import 'package:teletech_drivers/core/network/api_json_parsers.dart';
import 'package:teletech_drivers/features/attendance/domain/entities/attendance_day.dart';

abstract final class AttendanceDayDto {
  static AttendanceDay fromJson(Map<String, dynamic> json) {
    final driverRaw = json[ApiJsonKeys.driverId] ?? json[ApiJsonKeys.id];
    final status = json[ApiJsonKeys.status];
    if (driverRaw is! String || status is! String) {
      throw const FormatException('Invalid attendance day');
    }
    final workDate = json['work_date'] is String
        ? json['work_date'] as String
        : '';
    return AttendanceDay(
      driverId: driverRaw,
      driverNameEn: _string(json[ApiJsonKeys.nameEn] ?? json['driver_name_en']),
      driverNameAr: _string(json[ApiJsonKeys.nameAr] ?? json['driver_name_ar']),
      workDate: workDate,
      status: status,
      checkedInAt: ApiJsonParsers.optionalDateTime(json['checked_in_at']),
      checkedOutAt: ApiJsonParsers.optionalDateTime(json['checked_out_at']),
      onSiteHours: ApiJsonParsers.optionalDouble(json['on_site_hours']),
      checkInDistanceM: ApiJsonParsers.optionalInt(json['check_in_distance_m']),
      source: _string(json['source']),
      adjustmentReason: _string(json['adjustment_reason']),
    );
  }

  static AttendanceTotals totalsFromJson(Object? json) {
    if (json is! Map) {
      return const AttendanceTotals(
        daysPresent: 0,
        daysAbsent: 0,
        totalOnSiteHours: 0,
      );
    }
    return AttendanceTotals(
      daysPresent: ApiJsonParsers.optionalInt(json['days_present']) ?? 0,
      daysAbsent: ApiJsonParsers.optionalInt(json['days_absent']) ?? 0,
      totalOnSiteHours:
          ApiJsonParsers.optionalDouble(json['total_on_site_hours']) ?? 0,
    );
  }

  static String? _string(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
