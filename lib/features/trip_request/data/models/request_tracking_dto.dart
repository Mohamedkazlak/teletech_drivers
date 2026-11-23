import 'package:equatable/equatable.dart';
import 'package:teletech_drivers/core/constants/api_json_keys.dart';
import 'package:teletech_drivers/core/network/api_json_parsers.dart';
import 'package:teletech_drivers/features/auth/data/mappers/user_role_mapper.dart';
import 'package:teletech_drivers/features/auth/domain/entities/user_role.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/request_tracking.dart';

/// `tracking` object on a trip request or the requester's trip.
final class RequestTrackingDto extends Equatable {
  const RequestTrackingDto({
    required this.stage,
    required this.timeline,
    this.rejectionReason,
    this.driver,
    this.scheduledAt,
    this.vehicle,
  });

  final RequestTrackingStage stage;
  final List<RequestTrackingEventDto> timeline;
  final String? rejectionReason;
  final RequestTrackingDriverDto? driver;
  final DateTime? scheduledAt;
  final RequestTrackingVehicleDto? vehicle;

  factory RequestTrackingDto.fromJson(Map<String, dynamic> json) {
    final stageRaw = json[ApiJsonKeys.stage];
    if (stageRaw is! String || stageRaw.isEmpty) {
      throw const FormatException('Invalid tracking stage');
    }

    return RequestTrackingDto(
      stage: RequestTrackingStage.parse(stageRaw),
      timeline: [
        for (final item in ApiJsonParsers.objectList(
          json[ApiJsonKeys.timeline],
          ApiJsonKeys.timeline,
        ))
          RequestTrackingEventDto.fromJson(item),
      ],
      rejectionReason: ApiJsonParsers.optionalString(
        json[ApiJsonKeys.rejectionReason],
      ),
      driver: _driver(json[ApiJsonKeys.driver]),
      scheduledAt: ApiJsonParsers.optionalDateTime(json[ApiJsonKeys.scheduledAt]),
      vehicle: _vehicle(json[ApiJsonKeys.vehicle]),
    );
  }

  static RequestTrackingDriverDto? _driver(Object? raw) {
    if (raw == null) return null;
    final json = ApiJsonParsers.requireMap(raw, ApiJsonKeys.driver);
    return RequestTrackingDriverDto(
      nameEn: ApiJsonParsers.optionalString(json[ApiJsonKeys.nameEn]),
      nameAr: ApiJsonParsers.optionalString(json[ApiJsonKeys.nameAr]),
      phone: ApiJsonParsers.optionalString(json[ApiJsonKeys.phone]),
    );
  }

  static RequestTrackingVehicleDto? _vehicle(Object? raw) {
    if (raw == null) return null;
    final json = ApiJsonParsers.requireMap(raw, ApiJsonKeys.vehicle);
    final license = ApiJsonParsers.optionalString(json[ApiJsonKeys.carLicense]);
    if (license == null) {
      throw const FormatException('Invalid tracking vehicle');
    }
    return RequestTrackingVehicleDto(carLicense: license);
  }

  RequestTracking toEntity() {
    return RequestTracking(
      stage: stage,
      timeline: [for (final event in timeline) event.toEntity()],
      rejectionReason: rejectionReason,
      driver: driver?.toEntity(),
      scheduledAt: scheduledAt,
      vehicle: vehicle?.toEntity(),
    );
  }

  @override
  List<Object?> get props => [
    stage,
    timeline,
    rejectionReason,
    driver,
    scheduledAt,
    vehicle,
  ];
}

final class RequestTrackingEventDto extends Equatable {
  const RequestTrackingEventDto({
    required this.stage,
    required this.actorRole,
    this.reachedAt,
  });

  final RequestTrackingStage stage;
  final DateTime? reachedAt;
  final UserRole? actorRole;

  factory RequestTrackingEventDto.fromJson(Map<String, dynamic> json) {
    final stageRaw = json[ApiJsonKeys.stage];
    if (stageRaw is! String || stageRaw.isEmpty) {
      throw const FormatException('Invalid tracking event stage');
    }
    final roleRaw = ApiJsonParsers.optionalString(json[ApiJsonKeys.actorRole]);

    return RequestTrackingEventDto(
      stage: RequestTrackingStage.parse(stageRaw),
      reachedAt: ApiJsonParsers.optionalDateTime(json[ApiJsonKeys.reachedAt]),
      actorRole: roleRaw == null ? null : UserRoleMapper.fromApi(roleRaw),
    );
  }

  RequestTrackingEvent toEntity() {
    return RequestTrackingEvent(
      stage: stage,
      reachedAt: reachedAt,
      actorRole: actorRole,
    );
  }

  @override
  List<Object?> get props => [stage, reachedAt, actorRole];
}

final class RequestTrackingDriverDto extends Equatable {
  const RequestTrackingDriverDto({this.nameEn, this.nameAr, this.phone});

  final String? nameEn;
  final String? nameAr;
  final String? phone;

  RequestTrackingDriver toEntity() {
    return RequestTrackingDriver(nameEn: nameEn, nameAr: nameAr, phone: phone);
  }

  @override
  List<Object?> get props => [nameEn, nameAr, phone];
}

final class RequestTrackingVehicleDto extends Equatable {
  const RequestTrackingVehicleDto({required this.carLicense});

  final String carLicense;

  RequestTrackingVehicle toEntity() {
    return RequestTrackingVehicle(carLicense: carLicense);
  }

  @override
  List<Object?> get props => [carLicense];
}
