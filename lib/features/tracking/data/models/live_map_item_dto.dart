import 'package:equatable/equatable.dart';
import 'package:teletech_drivers/core/constants/api_json_keys.dart';
import 'package:teletech_drivers/core/network/api_json_parsers.dart';
import 'package:teletech_drivers/features/auth/data/models/user_dto.dart';

/// Trip object nested in a live-map row.
final class LiveMapTripDto extends Equatable {
  const LiveMapTripDto({
    required this.id,
    required this.status,
    required this.pickupSummary,
    required this.destinationSummary,
    this.scheduledAt,
    this.goingStartedAt,
  });

  final String id;
  final String status;
  final String pickupSummary;
  final String destinationSummary;
  final DateTime? scheduledAt;
  final DateTime? goingStartedAt;

  factory LiveMapTripDto.fromJson(Map<String, dynamic> json) {
    return LiveMapTripDto(
      id: ApiJsonParsers.requireNonEmptyString(json[ApiJsonKeys.id], 'trip id'),
      status: ApiJsonParsers.requireNonEmptyString(
        json[ApiJsonKeys.status],
        'trip status',
      ),
      pickupSummary: ApiJsonParsers.optionalString(
            json[ApiJsonKeys.pickupSummary],
          ) ??
          '',
      destinationSummary: ApiJsonParsers.optionalString(
            json[ApiJsonKeys.destinationSummary],
          ) ??
          '',
      scheduledAt: ApiJsonParsers.optionalDateTime(
        json[ApiJsonKeys.scheduledAt],
      ),
      goingStartedAt: ApiJsonParsers.optionalDateTime(
        json[ApiJsonKeys.goingStartedAt],
      ),
    );
  }

  @override
  List<Object?> get props => [
    id,
    status,
    pickupSummary,
    destinationSummary,
    scheduledAt,
    goingStartedAt,
  ];
}

/// One `GET /live-map` row.
final class LiveMapItemDto extends Equatable {
  const LiveMapItemDto({
    required this.driver,
    required this.isStale,
    required this.isTracking,
    this.state,
    this.trip,
    this.lat,
    this.lng,
    this.heading,
    this.speed,
    this.accuracy,
    this.updatedAt,
    this.lastSeenAt,
  });

  final UserDto driver;
  final String? state;
  final LiveMapTripDto? trip;
  final double? lat;
  final double? lng;
  final double? heading;
  final double? speed;
  final double? accuracy;
  final DateTime? updatedAt;
  final DateTime? lastSeenAt;
  final bool isStale;
  final bool isTracking;

  factory LiveMapItemDto.fromJson(Map<String, dynamic> json) {
    final tripJson = json[ApiJsonKeys.trip];
    final isStale = json[ApiJsonKeys.isStale];
    final isTracking = json[ApiJsonKeys.isTracking];
    if (isStale is! bool) {
      throw const FormatException('Invalid is_stale');
    }
    if (isTracking is! bool) {
      throw const FormatException('Invalid is_tracking');
    }

    return LiveMapItemDto(
      driver: UserDto.fromJson(
        ApiJsonParsers.requireMap(json[ApiJsonKeys.driver], 'driver'),
      ),
      trip: tripJson == null
          ? null
          : LiveMapTripDto.fromJson(
              ApiJsonParsers.requireMap(tripJson, 'trip'),
            ),
      lat: ApiJsonParsers.optionalDouble(json[ApiJsonKeys.lat]),
      lng: ApiJsonParsers.optionalDouble(json[ApiJsonKeys.lng]),
      heading: ApiJsonParsers.optionalDouble(json[ApiJsonKeys.heading]),
      speed: ApiJsonParsers.optionalDouble(json[ApiJsonKeys.speed]),
      accuracy: ApiJsonParsers.optionalDouble(json[ApiJsonKeys.accuracy]),
      updatedAt: ApiJsonParsers.optionalDateTime(json[ApiJsonKeys.updatedAt]),
      lastSeenAt: ApiJsonParsers.optionalDateTime(json[ApiJsonKeys.lastSeenAt]),
      state: ApiJsonParsers.optionalString(json[ApiJsonKeys.state]),
      isStale: isStale,
      isTracking: isTracking,
    );
  }

  @override
  List<Object?> get props => [
    driver,
    trip,
    lat,
    lng,
    heading,
    speed,
    accuracy,
    updatedAt,
    lastSeenAt,
    state,
    isStale,
    isTracking,
  ];
}
