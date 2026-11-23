import 'package:teletech_drivers/features/place/data/models/place_dto.dart';
import 'package:teletech_drivers/features/place/domain/entities/place.dart';

/// Maps [PlaceDto] → [Place]. `created_at` is copied as UTC or left null.
abstract final class PlaceDtoMapper {
  static Place toEntity(PlaceDto dto) {
    return Place(
      id: dto.id,
      nameEn: dto.nameEn,
      nameAr: dto.nameAr,
      isActive: dto.isActive,
      createdAt: dto.createdAt,
      latitude: dto.latitude,
      longitude: dto.longitude,
      address: dto.address,
      isHeadquarters: dto.isHeadquarters,
    );
  }
}
