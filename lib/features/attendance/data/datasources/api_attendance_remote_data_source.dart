import 'package:teletech_drivers/core/constants/api_json_keys.dart';
import 'package:teletech_drivers/core/constants/api_paths.dart';
import 'package:teletech_drivers/core/network/api_client.dart';
import 'package:teletech_drivers/core/network/api_json_parsers.dart';
import 'package:teletech_drivers/features/attendance/data/datasources/attendance_remote_data_source.dart';
import 'package:teletech_drivers/features/attendance/data/models/attendance_day_dto.dart';
import 'package:teletech_drivers/features/attendance/domain/entities/attendance_day.dart';
import 'package:teletech_drivers/features/attendance/domain/entities/attendance_summary.dart';
import 'package:teletech_drivers/features/attendance/domain/entities/attendance_today.dart';

class ApiAttendanceRemoteDataSource implements AttendanceRemoteDataSource {
  const ApiAttendanceRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<AttendanceToday> today() async {
    final response = await apiClient.get(ApiPaths.attendanceToday);
    final json = _map(response.data);
    final status = json[ApiJsonKeys.status];
    final workDate = json['work_date'];
    if (status is! String || workDate is! String) {
      throw const FormatException('Invalid attendance today');
    }
    final attendance = json['attendance'];
    DateTime? checkedIn;
    DateTime? checkedOut;
    if (attendance is Map) {
      checkedIn = ApiJsonParsers.optionalDateTime(attendance['checked_in_at']);
      checkedOut = ApiJsonParsers.optionalDateTime(
        attendance['checked_out_at'],
      );
    }
    return AttendanceToday(
      workDate: workDate,
      status: status,
      checkedInAt: checkedIn,
      checkedOutAt: checkedOut,
    );
  }

  @override
  Future<AttendanceHistory> history({
    required String path,
    required String period,
    String? date,
    String? driverId,
    String? status,
  }) async {
    final days = <AttendanceDay>[];
    AttendanceTotals? totals;
    var page = 1;
    while (page <= 20) {
      final response = await apiClient.get(
        path,
        queryParameters: {
          ApiJsonKeys.period: period,
          ApiJsonKeys.date: ?date,
          ApiJsonKeys.driverId: ?driverId,
          ApiJsonKeys.status: ?status,
          ApiJsonKeys.page: page,
          ApiJsonKeys.perPage: 100,
        },
      );
      final json = _map(response.data);
      totals ??= AttendanceDayDto.totalsFromJson(json[ApiJsonKeys.totals]);
      final data = json[ApiJsonKeys.data];
      if (data is List) {
        for (final item in data) {
          if (item is Map) {
            days.add(
              AttendanceDayDto.fromJson(Map<String, dynamic>.from(item)),
            );
          }
        }
      }
      final meta = json[ApiJsonKeys.meta];
      final last = meta is Map
          ? ApiJsonParsers.optionalInt(meta['last_page'])
          : 1;
      if (last == null || page >= last) break;
      page += 1;
    }
    return AttendanceHistory(
      days: days,
      totals:
          totals ??
          const AttendanceTotals(
            daysPresent: 0,
            daysAbsent: 0,
            totalOnSiteHours: 0,
          ),
    );
  }

  @override
  Future<AttendanceSummary> todaySummary() async {
    final response = await apiClient.get(ApiPaths.attendanceTodaySummary);
    final body = _map(response.data);
    final json = body[ApiJsonKeys.data];
    if (json is! Map) {
      throw const FormatException('Invalid attendance summary');
    }
    return AttendanceSummary(
      workDate: json['work_date'] is String ? json['work_date'] as String : '',
      offDay: json['off_day'] == true,
      present: _rows(json['present']),
      checkedIn: _rows(json['checked_in']),
      checkedOut: _rows(json['checked_out']),
      absent: _rows(json['absent']),
    );
  }

  @override
  Future<AttendanceQrCode> qr() async {
    final response = await apiClient.get(ApiPaths.attendanceQr);
    final json = _map(response.data);
    final payload = json['payload'];
    if (payload is! String || payload.isEmpty) {
      throw const FormatException('Invalid attendance QR');
    }
    return AttendanceQrCode(
      payload: payload,
      hqName: json['hq_name'] is String
          ? json['hq_name'] as String
          : 'Company Headquarters',
      version: ApiJsonParsers.optionalInt(json['version']) ?? 1,
    );
  }

  @override
  Future<void> scan({
    required String path,
    required String qrPayload,
    required double lat,
    required double lng,
    required double accuracyM,
    required bool isMocked,
  }) async {
    await apiClient.post(
      path,
      data: {
        'qr_payload': qrPayload,
        ApiJsonKeys.lat: lat,
        ApiJsonKeys.lng: lng,
        'accuracy_m': accuracyM,
        'is_mocked': isMocked,
      },
    );
  }

  @override
  Future<void> adjust(Map<String, dynamic> body) async {
    await apiClient.post(ApiPaths.attendanceAdjust, data: body);
  }

  static List<AttendanceDay> _rows(Object? value) {
    if (value is! List) return const [];
    return [
      for (final item in value)
        if (item is Map)
          AttendanceDayDto.fromJson(Map<String, dynamic>.from(item)),
    ];
  }

  static Map<String, dynamic> _map(Object? data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const FormatException('Expected JSON object response');
  }
}
