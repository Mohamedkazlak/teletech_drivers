import 'package:equatable/equatable.dart';
import 'package:teletech_drivers/core/constants/api_json_keys.dart';
import 'package:teletech_drivers/core/network/api_json_parsers.dart';

/// Nested pickup/destination snapshot on trip requests and passengers.
final class PlaceSnapshotDto extends Equatable {
  const PlaceSnapshotDto({
    this.placeId,
    required this.name,
    this.lat,
    this.lng,
    this.address,
  });

  final String? placeId;
  final String name;
  final double? lat;
  final double? lng;
  final String? address;

  factory PlaceSnapshotDto.fromJson(Map<String, dynamic> json) {
    final name = ApiJsonParsers.optionalString(json[ApiJsonKeys.name]) ?? '';
    return PlaceSnapshotDto(
      placeId: ApiJsonParsers.optionalString(json[ApiJsonKeys.placeId]),
      name: name,
      lat: ApiJsonParsers.optionalDouble(json[ApiJsonKeys.lat]),
      lng: ApiJsonParsers.optionalDouble(json[ApiJsonKeys.lng]),
      address: ApiJsonParsers.optionalString(json[ApiJsonKeys.address]),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      ApiJsonKeys.placeId: placeId,
      ApiJsonKeys.name: name,
      ApiJsonKeys.lat: lat,
      ApiJsonKeys.lng: lng,
      ApiJsonKeys.address: address,
    };
  }

  /// Body for create: either `place_id` or custom pin fields.
  Map<String, dynamic> toCreateBody() {
    final id = placeId;
    if (id != null && id.isNotEmpty && !id.startsWith('custom:')) {
      return {ApiJsonKeys.placeId: id};
    }
    return {
      ApiJsonKeys.name: name,
      ApiJsonKeys.lat: lat,
      ApiJsonKeys.lng: lng,
      if (address != null) ApiJsonKeys.address: address,
    };
  }

  @override
  List<Object?> get props => [placeId, name, lat, lng, address];
}
