import 'package:equatable/equatable.dart';
import 'package:teletech_drivers/core/constants/api_json_keys.dart';
import 'package:teletech_drivers/core/network/api_json_parsers.dart';
import 'package:teletech_drivers/features/auth/data/models/user_dto.dart';

/// API driver recommendation JSON (`DriverRecommendationResource`).
final class DriverRecommendationDto extends Equatable {
  const DriverRecommendationDto({
    required this.driver,
    required this.tier,
    required this.hasFavoriteMatch,
    required this.hasConflict,
    required this.isUnavailable,
    required this.needsConfirmation,
    required this.tripsThisWeek,
    this.isOnActiveTrip = false,
  });

  final UserDto driver;
  final int tier;
  final bool hasFavoriteMatch;
  final bool hasConflict;
  final bool isUnavailable;
  final bool needsConfirmation;
  final int tripsThisWeek;

  /// True when the driver has a trip in going, at destination, or returning.
  final bool isOnActiveTrip;

  factory DriverRecommendationDto.fromJson(Map<String, dynamic> json) {
    return DriverRecommendationDto(
      driver: UserDto.fromJson(
        ApiJsonParsers.requireMap(json[ApiJsonKeys.driver], 'driver'),
      ),
      tier: ApiJsonParsers.requireInt(json[ApiJsonKeys.tier], 'tier'),
      hasFavoriteMatch: ApiJsonParsers.readBool(
        json[ApiJsonKeys.hasFavoriteMatch],
      ),
      hasConflict: ApiJsonParsers.readBool(json[ApiJsonKeys.hasConflict]),
      isUnavailable: ApiJsonParsers.readBool(json[ApiJsonKeys.isUnavailable]),
      needsConfirmation: ApiJsonParsers.readBool(
        json[ApiJsonKeys.needsConfirmation],
      ),
      isOnActiveTrip: ApiJsonParsers.readBool(
        json[ApiJsonKeys.isOnActiveTrip],
      ),
      tripsThisWeek:
          ApiJsonParsers.optionalInt(json[ApiJsonKeys.tripsThisWeek]) ?? 0,
    );
  }

  @override
  List<Object?> get props => [
    driver,
    tier,
    hasFavoriteMatch,
    hasConflict,
    isUnavailable,
    needsConfirmation,
    tripsThisWeek,
    isOnActiveTrip,
  ];
}
