import 'package:equatable/equatable.dart';
import 'package:teletech_drivers/core/constants/api_json_keys.dart';
import 'package:teletech_drivers/core/network/api_json_parsers.dart';
import 'package:teletech_drivers/features/auth/data/models/user_dto.dart';
import 'package:teletech_drivers/features/trip/data/mappers/trip_status_mapper.dart';
import 'package:teletech_drivers/features/trip/data/models/trip_passenger_dto.dart';
import 'package:teletech_drivers/features/trip/data/models/trip_requester_dto.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_status.dart';
import 'package:teletech_drivers/features/trip_request/data/mappers/trip_confirmation_status_mapper.dart';
import 'package:teletech_drivers/features/trip_request/data/models/request_tracking_dto.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_confirmation_status.dart';

/// API trip JSON (`TripResource` / `TripSummaryResource`).
///
/// Summary responses omit [startLat], [startLng], [goingRoute], [returnRoute].
final class TripDto extends Equatable {
  const TripDto({
    required this.id,
    required this.scheduledAt,
    required this.status,
    required this.createdBy,
    required this.pickupSummary,
    required this.destinationSummary,
    required this.passengers,
    required this.createdAt,
    this.driverId,
    this.driver,
    this.goingStartedAt,
    this.goingEndedAt,
    this.returnStartedAt,
    this.finishedAt,
    this.goingDistanceM,
    this.returnDistanceM,
    this.totalDistanceM,
    this.startLat,
    this.startLng,
    this.goingRoute,
    this.returnRoute,
    this.confirmationStatus,
    this.driverShowedUp,
    this.requester,
    this.requesters = const [],
    this.passengerCount = 0,
    this.tracking,
  });

  final String id;
  final String? driverId;
  final UserDto? driver;
  final DateTime scheduledAt;
  final TripStatus status;
  final String createdBy;
  final String pickupSummary;
  final String destinationSummary;
  final DateTime? goingStartedAt;
  final DateTime? goingEndedAt;
  final DateTime? returnStartedAt;
  final DateTime? finishedAt;
  final double? goingDistanceM;
  final double? returnDistanceM;
  final double? totalDistanceM;
  final List<TripPassengerDto> passengers;
  final DateTime createdAt;
  final double? startLat;
  final double? startLng;
  final String? goingRoute;
  final String? returnRoute;
  final TripConfirmationStatus? confirmationStatus;
  final bool? driverShowedUp;
  final TripRequesterDto? requester;
  final List<TripRequesterDto> requesters;

  /// `passenger_count` from the API. Zero when the field is absent.
  final int passengerCount;
  final RequestTrackingDto? tracking;

  factory TripDto.fromJson(Map<String, dynamic> json) {
    final statusRaw = json[ApiJsonKeys.status];
    if (statusRaw is! String) {
      throw const FormatException('Invalid trip status');
    }
    final driverJson = json[ApiJsonKeys.driver];

    return TripDto(
      id: ApiJsonParsers.requireNonEmptyString(json[ApiJsonKeys.id], 'trip id'),
      driverId: ApiJsonParsers.optionalString(json[ApiJsonKeys.driverId]),
      driver: driverJson == null
          ? null
          : UserDto.fromJson(ApiJsonParsers.requireMap(driverJson, 'driver')),
      scheduledAt: ApiJsonParsers.requireDateTime(
        json[ApiJsonKeys.scheduledAt],
        'scheduled_at',
      ),
      status: TripStatusMapper.fromApi(statusRaw),
      createdBy: ApiJsonParsers.requireNonEmptyString(
        json[ApiJsonKeys.createdBy],
        'created_by',
      ),
      pickupSummary:
          ApiJsonParsers.optionalString(json[ApiJsonKeys.pickupSummary]) ?? '',
      destinationSummary:
          ApiJsonParsers.optionalString(json[ApiJsonKeys.destinationSummary]) ??
          '',
      goingStartedAt: ApiJsonParsers.optionalDateTime(
        json[ApiJsonKeys.goingStartedAt],
      ),
      goingEndedAt: ApiJsonParsers.optionalDateTime(
        json[ApiJsonKeys.goingEndedAt],
      ),
      returnStartedAt: ApiJsonParsers.optionalDateTime(
        json[ApiJsonKeys.returnStartedAt],
      ),
      finishedAt: ApiJsonParsers.optionalDateTime(json[ApiJsonKeys.finishedAt]),
      goingDistanceM: ApiJsonParsers.optionalDouble(
        json[ApiJsonKeys.goingDistanceM],
      ),
      returnDistanceM: ApiJsonParsers.optionalDouble(
        json[ApiJsonKeys.returnDistanceM],
      ),
      totalDistanceM: ApiJsonParsers.optionalDouble(
        json[ApiJsonKeys.totalDistanceM],
      ),
      passengers: [
        for (final item in ApiJsonParsers.objectList(
          json[ApiJsonKeys.passengers],
          ApiJsonKeys.passengers,
        ))
          TripPassengerDto.fromJson(item),
      ],
      createdAt: ApiJsonParsers.requireDateTime(
        json[ApiJsonKeys.createdAt],
        'created_at',
      ),
      startLat: ApiJsonParsers.optionalDouble(json[ApiJsonKeys.startLat]),
      startLng: ApiJsonParsers.optionalDouble(json[ApiJsonKeys.startLng]),
      goingRoute: ApiJsonParsers.optionalString(json[ApiJsonKeys.goingRoute]),
      returnRoute: ApiJsonParsers.optionalString(json[ApiJsonKeys.returnRoute]),
      confirmationStatus: _confirmation(json[ApiJsonKeys.confirmationStatus]),
      driverShowedUp: ApiJsonParsers.optionalBool(
        json[ApiJsonKeys.driverShowedUp],
        ApiJsonKeys.driverShowedUp,
      ),
      requester: _requester(json[ApiJsonKeys.requester]),
      requesters: [
        for (final item in ApiJsonParsers.objectList(
          json[ApiJsonKeys.requesters],
          ApiJsonKeys.requesters,
        ))
          TripRequesterDto.fromJson(item),
      ],
      passengerCount:
          ApiJsonParsers.optionalInt(json[ApiJsonKeys.passengerCount]) ?? 0,
      tracking: _tracking(json[ApiJsonKeys.tracking]),
    );
  }

  @override
  List<Object?> get props => [
    id,
    driverId,
    driver,
    scheduledAt,
    status,
    createdBy,
    pickupSummary,
    destinationSummary,
    goingStartedAt,
    goingEndedAt,
    returnStartedAt,
    finishedAt,
    goingDistanceM,
    returnDistanceM,
    totalDistanceM,
    passengers,
    createdAt,
    startLat,
    startLng,
    goingRoute,
    returnRoute,
    confirmationStatus,
    driverShowedUp,
    requester,
    requesters,
    passengerCount,
    tracking,
  ];

  static TripRequesterDto? _requester(Object? value) {
    if (value == null) return null;
    return TripRequesterDto.fromJson(
      ApiJsonParsers.requireMap(value, ApiJsonKeys.requester),
    );
  }

  static TripConfirmationStatus? _confirmation(Object? value) {
    final raw = ApiJsonParsers.optionalString(value);
    if (raw == null) return null;
    return TripConfirmationStatusMapper.fromApi(raw);
  }

  static RequestTrackingDto? _tracking(Object? value) {
    if (value == null) return null;
    return RequestTrackingDto.fromJson(
      ApiJsonParsers.requireMap(value, ApiJsonKeys.tracking),
    );
  }
}
