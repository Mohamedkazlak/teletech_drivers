import 'package:equatable/equatable.dart';
import 'package:teletech_drivers/core/constants/api_json_keys.dart';
import 'package:teletech_drivers/core/network/api_json_parsers.dart';

/// One `breakdown` entry from `DriverStatsResource`.
final class StatsBucketDto extends Equatable {
  const StatsBucketDto({
    required this.label,
    required this.trips,
    required this.totalSeconds,
    required this.totalKm,
    this.from,
    this.to,
  });

  final String label;
  final DateTime? from;
  final DateTime? to;
  final int trips;
  final int totalSeconds;
  final double totalKm;

  factory StatsBucketDto.fromJson(Map<String, dynamic> json) {
    return StatsBucketDto(
      label: ApiJsonParsers.requireNonEmptyString(
        json[ApiJsonKeys.label],
        'label',
      ),
      from: ApiJsonParsers.optionalDateTime(json[ApiJsonKeys.from]),
      to: ApiJsonParsers.optionalDateTime(json[ApiJsonKeys.to]),
      trips: _requireInt(json[ApiJsonKeys.trips], 'trips'),
      totalSeconds: _requireInt(json[ApiJsonKeys.totalSeconds], 'total_seconds'),
      totalKm: _requireDouble(json[ApiJsonKeys.totalKm], 'total_km'),
    );
  }

  @override
  List<Object?> get props => [label, from, to, trips, totalSeconds, totalKm];
}

/// `GET /auth/me/stats` body. The resource is unwrapped.
final class DriverStatsDto extends Equatable {
  const DriverStatsDto({
    required this.period,
    required this.trips,
    required this.totalSeconds,
    required this.totalKm,
    required this.breakdown,
    this.from,
    this.to,
  });

  final String period;
  final DateTime? from;
  final DateTime? to;
  final int trips;
  final int totalSeconds;
  final double totalKm;
  final List<StatsBucketDto> breakdown;

  factory DriverStatsDto.fromJson(Map<String, dynamic> json) {
    final rawBreakdown = json[ApiJsonKeys.breakdown];
    if (rawBreakdown is! List) {
      throw const FormatException('Invalid breakdown');
    }
    return DriverStatsDto(
      period: ApiJsonParsers.requireNonEmptyString(
        json[ApiJsonKeys.period],
        'period',
      ),
      from: ApiJsonParsers.optionalDateTime(json[ApiJsonKeys.from]),
      to: ApiJsonParsers.optionalDateTime(json[ApiJsonKeys.to]),
      trips: _requireInt(json[ApiJsonKeys.trips], 'trips'),
      totalSeconds: _requireInt(json[ApiJsonKeys.totalSeconds], 'total_seconds'),
      totalKm: _requireDouble(json[ApiJsonKeys.totalKm], 'total_km'),
      breakdown: [
        for (final item in rawBreakdown)
          StatsBucketDto.fromJson(ApiJsonParsers.requireMap(item, 'breakdown')),
      ],
    );
  }

  @override
  List<Object?> get props => [
    period,
    from,
    to,
    trips,
    totalSeconds,
    totalKm,
    breakdown,
  ];
}

int _requireInt(Object? value, String field) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  throw FormatException('Invalid $field');
}

double _requireDouble(Object? value, String field) {
  if (value is num) return value.toDouble();
  throw FormatException('Invalid $field');
}
