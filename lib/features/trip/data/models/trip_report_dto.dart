import 'package:equatable/equatable.dart';
import 'package:teletech_drivers/core/constants/api_json_keys.dart';
import 'package:teletech_drivers/core/network/api_json_parsers.dart';
import 'package:teletech_drivers/features/trip/data/mappers/trip_status_mapper.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_status.dart';

/// API trip report JSON (`TripReportResource`).
final class TripReportDto extends Equatable {
  const TripReportDto({
    required this.status,
    required this.isInProgress,
    this.start,
    this.finish,
    this.goingDurationSeconds,
    this.waitingDurationSeconds,
    this.returnDurationSeconds,
    this.totalDurationSeconds,
    this.goingDistanceKm,
    this.returnDistanceKm,
    this.totalDistanceKm,
    this.goingRoute,
    this.returnRoute,
  });

  final TripStatus status;
  final bool isInProgress;
  final DateTime? start;
  final DateTime? finish;
  final int? goingDurationSeconds;
  final int? waitingDurationSeconds;
  final int? returnDurationSeconds;
  final int? totalDurationSeconds;
  final double? goingDistanceKm;
  final double? returnDistanceKm;
  final double? totalDistanceKm;
  final String? goingRoute;
  final String? returnRoute;

  factory TripReportDto.fromJson(Map<String, dynamic> json) {
    final statusRaw = json[ApiJsonKeys.status];
    if (statusRaw is! String) {
      throw const FormatException('Invalid trip report status');
    }

    return TripReportDto(
      status: TripStatusMapper.fromApi(statusRaw),
      isInProgress: ApiJsonParsers.readBool(json[ApiJsonKeys.isInProgress]),
      start: ApiJsonParsers.optionalDateTime(json[ApiJsonKeys.start]),
      finish: ApiJsonParsers.optionalDateTime(json[ApiJsonKeys.finish]),
      goingDurationSeconds: ApiJsonParsers.optionalInt(
        json[ApiJsonKeys.goingDurationSeconds],
      ),
      waitingDurationSeconds: ApiJsonParsers.optionalInt(
        json[ApiJsonKeys.waitingDurationSeconds],
      ),
      returnDurationSeconds: ApiJsonParsers.optionalInt(
        json[ApiJsonKeys.returnDurationSeconds],
      ),
      totalDurationSeconds: ApiJsonParsers.optionalInt(
        json[ApiJsonKeys.totalDurationSeconds],
      ),
      goingDistanceKm: ApiJsonParsers.optionalDouble(
        json[ApiJsonKeys.goingDistanceKm],
      ),
      returnDistanceKm: ApiJsonParsers.optionalDouble(
        json[ApiJsonKeys.returnDistanceKm],
      ),
      totalDistanceKm: ApiJsonParsers.optionalDouble(
        json[ApiJsonKeys.totalDistanceKm],
      ),
      goingRoute: ApiJsonParsers.optionalString(json[ApiJsonKeys.goingRoute]),
      returnRoute: ApiJsonParsers.optionalString(json[ApiJsonKeys.returnRoute]),
    );
  }

  @override
  List<Object?> get props => [
    status,
    isInProgress,
    start,
    finish,
    goingDurationSeconds,
    waitingDurationSeconds,
    returnDurationSeconds,
    totalDurationSeconds,
    goingDistanceKm,
    returnDistanceKm,
    totalDistanceKm,
    goingRoute,
    returnRoute,
  ];
}
