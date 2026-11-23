import 'package:teletech_drivers/features/auth/data/models/user_dto.dart';
import 'package:teletech_drivers/features/auth/domain/entities/app_user.dart';

/// Maps [UserDto] → [AppUser] (no business rules beyond display-name fallback).
abstract final class UserDtoMapper {
  static AppUser toEntity(UserDto dto) {
    final displayName = dto.nameEn ?? dto.nameAr ?? dto.email;

    return AppUser(
      id: dto.id,
      name: displayName,
      email: dto.email,
      role: dto.role,
      isActive: dto.isActive,
      phone: dto.phone,
      branch: dto.branch,
      nameEn: dto.nameEn ?? displayName,
      nameAr: dto.nameAr,
      isAvailable: dto.isAvailable,
      favoritePlaceIds: dto.favoritePlaceIds,
      deletedAt: dto.deletedAt,
      deletedBy: dto.deletedBy,
      mustChangePassword: dto.mustChangePassword,
    );
  }
}
