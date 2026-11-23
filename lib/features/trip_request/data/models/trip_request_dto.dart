import 'package:equatable/equatable.dart';
import 'package:teletech_drivers/core/constants/api_json_keys.dart';
import 'package:teletech_drivers/core/network/api_json_parsers.dart';
import 'package:teletech_drivers/features/auth/data/mappers/user_role_mapper.dart';
import 'package:teletech_drivers/features/auth/domain/entities/branch.dart';
import 'package:teletech_drivers/features/auth/domain/entities/user_role.dart';
import 'package:teletech_drivers/features/trip_request/data/mappers/trip_request_status_mapper.dart';
import 'package:teletech_drivers/features/trip_request/data/models/linked_trip_dto.dart';
import 'package:teletech_drivers/features/trip_request/data/models/place_snapshot_dto.dart';
import 'package:teletech_drivers/features/trip_request/data/models/request_tracking_dto.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request_status.dart';

/// API trip request JSON (`TripRequestResource`).
final class TripRequestDto extends Equatable {
  const TripRequestDto({
    required this.id,
    required this.employeeId,
    required this.pickup,
    required this.destination,
    required this.requestedAt,
    required this.notes,
    required this.status,
    required this.autoApproved,
    required this.createdAt,
    this.employeeNameEn,
    this.employeeNameAr,
    this.employeePhone,
    this.employeeBranch,
    this.requesterRole,
    this.tripId,
    this.rejectionReason,
    this.handledBy,
    this.handledAt,
    this.suggestedGroupId,
    this.trip,
    this.tracking,
  });

  final String id;
  final String employeeId;
  final String? employeeNameEn;
  final String? employeeNameAr;
  final String? employeePhone;
  final Branch? employeeBranch;
  final UserRole? requesterRole;
  final PlaceSnapshotDto pickup;
  final PlaceSnapshotDto destination;
  final DateTime requestedAt;
  final String notes;
  final TripRequestStatus status;
  final String? tripId;
  final String? rejectionReason;
  final String? handledBy;
  final DateTime? handledAt;
  final bool autoApproved;
  final String? suggestedGroupId;
  final DateTime createdAt;
  final LinkedTripDto? trip;
  final RequestTrackingDto? tracking;

  factory TripRequestDto.fromJson(Map<String, dynamic> json) {
    final id = ApiJsonParsers.requireNonEmptyString(
      json[ApiJsonKeys.id],
      'trip request id',
    );
    final employeeId = ApiJsonParsers.requireNonEmptyString(
      json[ApiJsonKeys.employeeId],
      'employee_id',
    );
    final statusRaw = json[ApiJsonKeys.status];
    if (statusRaw is! String) {
      throw const FormatException('Invalid trip request status');
    }

    final requesterRaw = ApiJsonParsers.optionalString(
      json[ApiJsonKeys.requesterRole],
    );

    return TripRequestDto(
      id: id,
      employeeId: employeeId,
      employeeNameEn: ApiJsonParsers.optionalString(
        json[ApiJsonKeys.employeeNameEn],
      ),
      employeeNameAr: ApiJsonParsers.optionalString(
        json[ApiJsonKeys.employeeNameAr],
      ),
      employeePhone: ApiJsonParsers.optionalString(
        json[ApiJsonKeys.employeePhone],
      ),
      employeeBranch: ApiJsonParsers.optionalBranch(
        json[ApiJsonKeys.employeeBranch],
      ),
      requesterRole: requesterRaw == null
          ? null
          : UserRoleMapper.fromApi(requesterRaw),
      pickup: PlaceSnapshotDto.fromJson(
        ApiJsonParsers.requireMap(json[ApiJsonKeys.pickup], 'pickup'),
      ),
      destination: PlaceSnapshotDto.fromJson(
        ApiJsonParsers.requireMap(json[ApiJsonKeys.destination], 'destination'),
      ),
      requestedAt: ApiJsonParsers.requireDateTime(
        json[ApiJsonKeys.requestedAt],
        'requested_at',
      ),
      notes: ApiJsonParsers.optionalString(json[ApiJsonKeys.notes]) ?? '',
      status: TripRequestStatusMapper.fromApi(statusRaw),
      tripId: ApiJsonParsers.optionalString(json[ApiJsonKeys.tripId]),
      rejectionReason: ApiJsonParsers.optionalString(
        json[ApiJsonKeys.rejectionReason],
      ),
      handledBy: ApiJsonParsers.optionalString(json[ApiJsonKeys.handledBy]),
      handledAt: ApiJsonParsers.optionalDateTime(json[ApiJsonKeys.handledAt]),
      autoApproved: ApiJsonParsers.readBool(json[ApiJsonKeys.autoApproved]),
      suggestedGroupId: ApiJsonParsers.optionalString(
        json[ApiJsonKeys.suggestedGroupId],
      ),
      createdAt: ApiJsonParsers.requireDateTime(
        json[ApiJsonKeys.createdAt],
        'created_at',
      ),
      trip: _readTrip(json[ApiJsonKeys.trip]),
      tracking: _readTracking(json[ApiJsonKeys.tracking]),
    );
  }

  static LinkedTripDto? _readTrip(Object? raw) {
    if (raw == null) return null;
    return LinkedTripDto.fromJson(ApiJsonParsers.requireMap(raw, 'trip'));
  }

  static RequestTrackingDto? _readTracking(Object? raw) {
    if (raw == null) return null;
    return RequestTrackingDto.fromJson(
      ApiJsonParsers.requireMap(raw, ApiJsonKeys.tracking),
    );
  }

  @override
  List<Object?> get props => [
    id,
    employeeId,
    employeeNameEn,
    employeeNameAr,
    employeePhone,
    employeeBranch,
    requesterRole,
    pickup,
    destination,
    requestedAt,
    notes,
    status,
    tripId,
    rejectionReason,
    handledBy,
    handledAt,
    autoApproved,
    suggestedGroupId,
    createdAt,
    trip,
    tracking,
  ];
}
