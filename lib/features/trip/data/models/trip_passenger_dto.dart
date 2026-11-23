import 'package:equatable/equatable.dart';
import 'package:teletech_drivers/core/constants/api_json_keys.dart';
import 'package:teletech_drivers/core/network/api_json_parsers.dart';
import 'package:teletech_drivers/features/auth/domain/entities/branch.dart';
import 'package:teletech_drivers/features/trip_request/data/models/place_snapshot_dto.dart';

/// API trip passenger JSON (`TripPassengerResource`).
final class TripPassengerDto extends Equatable {
  const TripPassengerDto({
    required this.employeeId,
    required this.requestId,
    required this.pickup,
    required this.destination,
    this.nameEn,
    this.nameAr,
    this.phone,
    this.branch,
  });

  final String employeeId;
  final String? nameEn;
  final String? nameAr;
  final String? phone;
  final Branch? branch;
  final String requestId;
  final PlaceSnapshotDto pickup;
  final PlaceSnapshotDto destination;

  factory TripPassengerDto.fromJson(Map<String, dynamic> json) {
    return TripPassengerDto(
      employeeId: ApiJsonParsers.requireNonEmptyString(
        json[ApiJsonKeys.employeeId],
        'passenger employee_id',
      ),
      nameEn: ApiJsonParsers.optionalString(json[ApiJsonKeys.nameEn]),
      nameAr: ApiJsonParsers.optionalString(json[ApiJsonKeys.nameAr]),
      phone: ApiJsonParsers.optionalString(json[ApiJsonKeys.phone]),
      branch: ApiJsonParsers.optionalBranch(json[ApiJsonKeys.branch]),
      requestId: ApiJsonParsers.requireNonEmptyString(
        json[ApiJsonKeys.requestId],
        'passenger request_id',
      ),
      pickup: PlaceSnapshotDto.fromJson(
        ApiJsonParsers.requireMap(json[ApiJsonKeys.pickup], 'pickup'),
      ),
      destination: PlaceSnapshotDto.fromJson(
        ApiJsonParsers.requireMap(json[ApiJsonKeys.destination], 'destination'),
      ),
    );
  }

  @override
  List<Object?> get props => [
    employeeId,
    nameEn,
    nameAr,
    phone,
    branch,
    requestId,
    pickup,
    destination,
  ];
}
