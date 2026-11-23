import 'package:equatable/equatable.dart';
import 'package:teletech_drivers/core/constants/api_json_keys.dart';
import 'package:teletech_drivers/core/network/api_json_parsers.dart';
import 'package:teletech_drivers/features/trip/data/mappers/trip_status_mapper.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_status.dart';
import 'package:teletech_drivers/features/trip_request/data/mappers/trip_confirmation_status_mapper.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_confirmation_status.dart';

/// `trip` object nested on a trip-request resource.
final class LinkedTripDto extends Equatable {
  const LinkedTripDto({
    required this.id,
    required this.status,
    this.driverNameEn,
    this.driverNameAr,
    this.confirmationStatus,
    this.driverShowedUp,
  });

  final String id;
  final TripStatus status;
  final String? driverNameEn;
  final String? driverNameAr;
  final TripConfirmationStatus? confirmationStatus;
  final bool? driverShowedUp;

  factory LinkedTripDto.fromJson(Map<String, dynamic> json) {
    final statusRaw = json[ApiJsonKeys.status];
    if (statusRaw is! String) {
      throw const FormatException('Invalid linked trip status');
    }

    return LinkedTripDto(
      id: ApiJsonParsers.requireNonEmptyString(json[ApiJsonKeys.id], 'trip id'),
      status: TripStatusMapper.fromApi(statusRaw),
      driverNameEn: ApiJsonParsers.optionalString(json[ApiJsonKeys.driverNameEn]),
      driverNameAr: ApiJsonParsers.optionalString(json[ApiJsonKeys.driverNameAr]),
      confirmationStatus: _confirmation(json[ApiJsonKeys.confirmationStatus]),
      driverShowedUp: ApiJsonParsers.optionalBool(
        json[ApiJsonKeys.driverShowedUp],
        'driver_showed_up',
      ),
    );
  }

  static TripConfirmationStatus? _confirmation(Object? raw) {
    if (raw == null) return null;
    if (raw is! String || raw.trim().isEmpty) {
      throw const FormatException('Invalid confirmation_status');
    }
    return TripConfirmationStatusMapper.fromApi(raw);
  }

  @override
  List<Object?> get props => [
    id,
    status,
    driverNameEn,
    driverNameAr,
    confirmationStatus,
    driverShowedUp,
  ];
}
