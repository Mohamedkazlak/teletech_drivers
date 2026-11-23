import 'package:equatable/equatable.dart';
import 'package:teletech_drivers/core/constants/api_json_keys.dart';
import 'package:teletech_drivers/core/network/api_json_parsers.dart';
import 'package:teletech_drivers/features/auth/domain/entities/branch.dart';

/// API requester object on a driver trip (`TripRequesterResource`).
final class TripRequesterDto extends Equatable {
  const TripRequesterDto({
    required this.id,
    required this.nameEn,
    this.nameAr,
    this.phone,
    this.branch,
  });

  final String id;
  final String nameEn;
  final String? nameAr;
  final String? phone;
  final Branch? branch;

  factory TripRequesterDto.fromJson(Map<String, dynamic> json) {
    return TripRequesterDto(
      id: ApiJsonParsers.requireNonEmptyString(
        json[ApiJsonKeys.id],
        'requester id',
      ),
      nameEn: ApiJsonParsers.optionalString(json[ApiJsonKeys.nameEn]) ?? '',
      nameAr: ApiJsonParsers.optionalString(json[ApiJsonKeys.nameAr]),
      phone: ApiJsonParsers.optionalString(json[ApiJsonKeys.phone]),
      branch: ApiJsonParsers.optionalBranch(json[ApiJsonKeys.branch]),
    );
  }

  @override
  List<Object?> get props => [id, nameEn, nameAr, phone, branch];
}
