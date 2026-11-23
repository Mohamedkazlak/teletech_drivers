import 'package:teletech_drivers/features/auth/data/mappers/user_dto_mapper.dart';
import 'package:teletech_drivers/features/auth/data/models/user_dto.dart';
import 'package:teletech_drivers/features/auth/domain/entities/app_user.dart';
import 'package:teletech_drivers/features/drivers_admin/data/models/driver_completed_trip_dto.dart';
import 'package:teletech_drivers/features/drivers_admin/domain/entities/driver_completed_trip.dart';
import 'package:teletech_drivers/features/drivers_admin/domain/entities/driver_private_profile.dart';
import 'package:teletech_drivers/features/drivers_admin/domain/entities/driver_profile.dart';
import 'package:teletech_drivers/features/drivers_admin/domain/entities/driver_totals.dart';

/// Maps driver API resources onto domain types.
abstract final class DriverDtoMapper {
  static AppUser toAppUser(UserDto dto) => UserDtoMapper.toEntity(dto);

  static DriverProfile toProfile(UserDto dto) {
    final displayName = dto.nameEn ?? dto.nameAr ?? dto.email;
    return DriverProfile(
      id: dto.id,
      nameEn: dto.nameEn ?? displayName,
      nameAr: dto.nameAr ?? displayName,
      email: dto.email,
      phone: dto.phone ?? '',
      isActive: dto.isActive,
      privateProfile: DriverPrivateProfile(
        nationalId: dto.nationalId ?? '',
        carLicense: dto.carLicense ?? '',
        personalLicense: dto.personalLicense ?? '',
      ),
      isAvailable: dto.isAvailable,
      favoritePlaceIds: dto.favoritePlaceIds,
      totals: _totals(dto),
    );
  }

  static DriverCompletedTrip toCompletedTrip(DriverCompletedTripDto dto) {
    return DriverCompletedTrip(
      id: dto.id,
      scheduledAt: dto.scheduledAt,
      goingStartedAt: dto.goingStartedAt,
      finishedAt: dto.finishedAt,
      pickupSummary: dto.pickupSummary,
      destinationSummary: dto.destinationSummary,
      durationSeconds: dto.durationSeconds,
      distanceKm: dto.distanceKm,
      confirmationStatus: dto.confirmationStatus,
      driverShowedUp: dto.driverShowedUp,
    );
  }

  static DriverTotals? _totals(UserDto dto) {
    final trips = dto.lifetimeTrips;
    final seconds = dto.lifetimeSeconds;
    final km = dto.lifetimeKm;
    if (trips == null || seconds == null || km == null) return null;
    return DriverTotals(trips: trips, totalSeconds: seconds, totalKm: km);
  }
}
