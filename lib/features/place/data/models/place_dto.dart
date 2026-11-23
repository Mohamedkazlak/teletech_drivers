import 'package:equatable/equatable.dart';
import 'package:teletech_drivers/core/constants/api_json_keys.dart';
import 'package:teletech_drivers/core/network/api_json_parsers.dart';

/// API place JSON (`PlaceResource`).
final class PlaceDto extends Equatable {
  const PlaceDto({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.isActive,
    this.latitude,
    this.longitude,
    this.address,
    this.isHeadquarters = false,
    this.createdAt,
  });

  final String id;
  final String nameEn;
  final String nameAr;
  final bool isActive;
  final double? latitude;
  final double? longitude;
  final String? address;
  final bool isHeadquarters;

  /// ISO-8601 UTC, or null.
  final DateTime? createdAt;

  factory PlaceDto.fromJson(Map<String, dynamic> json) {
    final id = json[ApiJsonKeys.id];
    final nameEn = json[ApiJsonKeys.nameEn];
    final nameAr = json[ApiJsonKeys.nameAr];
    if (id is! String || id.isEmpty) {
      throw const FormatException('Invalid place id');
    }
    if (nameEn is! String || nameEn.trim().isEmpty) {
      throw const FormatException('Invalid place name_en');
    }
    if (nameAr is! String || nameAr.trim().isEmpty) {
      throw const FormatException('Invalid place name_ar');
    }

    final isActiveValue = json[ApiJsonKeys.isActive];
    final isActive = isActiveValue is bool ? isActiveValue : true;
    final hqValue = json[ApiJsonKeys.isHeadquarters];
    final isHeadquarters = hqValue is bool ? hqValue : false;

    final latitude = ApiJsonParsers.optionalDouble(json[ApiJsonKeys.latitude]);
    final longitude = ApiJsonParsers.optionalDouble(json[ApiJsonKeys.longitude]);
    final hasPair = latitude != null && longitude != null;

    return PlaceDto(
      id: id,
      nameEn: nameEn.trim(),
      nameAr: nameAr.trim(),
      isActive: isActive,
      latitude: hasPair ? latitude : null,
      longitude: hasPair ? longitude : null,
      address: _optionalString(json[ApiJsonKeys.address]),
      isHeadquarters: isHeadquarters,
      createdAt: ApiJsonParsers.optionalDateTime(json[ApiJsonKeys.createdAt]),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      ApiJsonKeys.id: id,
      ApiJsonKeys.nameEn: nameEn,
      ApiJsonKeys.nameAr: nameAr,
      ApiJsonKeys.isActive: isActive,
      ApiJsonKeys.latitude: latitude,
      ApiJsonKeys.longitude: longitude,
      ApiJsonKeys.address: address,
      ApiJsonKeys.isHeadquarters: isHeadquarters,
      ApiJsonKeys.createdAt: createdAt?.toUtc().toIso8601String(),
    };
  }

  Map<String, dynamic> toCreateBody() {
    return {
      ApiJsonKeys.nameEn: nameEn,
      ApiJsonKeys.nameAr: nameAr,
      ApiJsonKeys.isActive: isActive,
      ApiJsonKeys.isHeadquarters: isHeadquarters,
      if (latitude != null) ApiJsonKeys.latitude: latitude,
      if (longitude != null) ApiJsonKeys.longitude: longitude,
      if (address != null) ApiJsonKeys.address: address,
    };
  }

  Map<String, dynamic> toUpdateBody() {
    return {
      ApiJsonKeys.nameEn: nameEn,
      ApiJsonKeys.nameAr: nameAr,
      ApiJsonKeys.latitude: latitude,
      ApiJsonKeys.longitude: longitude,
      ApiJsonKeys.address: address,
      ApiJsonKeys.isHeadquarters: isHeadquarters,
      ApiJsonKeys.isActive: isActive,
    };
  }

  static String? _optionalString(Object? value) {
    if (value is! String || value.trim().isEmpty) return null;
    return value.trim();
  }

  @override
  List<Object?> get props => [
    id,
    nameEn,
    nameAr,
    isActive,
    latitude,
    longitude,
    address,
    isHeadquarters,
    createdAt,
  ];
}
