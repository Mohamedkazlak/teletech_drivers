import 'package:teletech_drivers/features/auth/domain/entities/app_user.dart';
import 'package:teletech_drivers/features/drivers_admin/domain/entities/driver_attendance_filter.dart';
import 'package:teletech_drivers/features/drivers_admin/domain/entities/driver_completed_trip.dart';
import 'package:teletech_drivers/features/drivers_admin/domain/entities/driver_profile.dart';

/// Repository: driver accounts managed by the drivers admin.
abstract interface class DriverRepository {
  /// Observer: public driver profiles (no private subdocuments).
  Stream<List<AppUser>> watchAllDrivers();

  /// Observer: drivers with private licenses joined for Drivers Admin.
  Stream<List<DriverProfile>> watchAllDriverProfiles();

  /// Observer: drivers filtered by today's check-in. Null is every driver.
  Stream<List<DriverProfile>> watchDriverProfiles({
    DriverAttendanceFilter? attendance,
  });

  /// Completed trips for [driverId] in one fleet period.
  Future<List<DriverCompletedTrip>> listDriverTrips({
    required String driverId,
    String? period,
    String? date,
  });

  /// Loads one driver with private profile for the details / edit screens.
  Future<DriverProfile> getDriverProfile(String driverId);

  /// Creates the driver account through the API.
  /// The drivers-admin session stays signed in.
  Future<void> createDriver({
    required String nameEn,
    required String nameAr,
    required String email,
    required String password,
    required String phone,
    required String nationalId,
    required String carLicense,
    required String personalLicense,
    List<String> favoritePlaceIds = const [],
  });

  /// Soft activate/deactivate. Drivers are never hard-deleted.
  Future<void> setDriverActive({
    required String driverId,
    required bool isActive,
  });

  /// Soft delete: sets isActive=false with deletedAt/deletedBy audit fields.
  Future<void> softDeleteDriver({
    required String driverId,
    required String deletedBy,
  });

  /// Updates public and private documents in one batch.
  Future<void> updateDriver({
    required String driverId,
    required String nameEn,
    required String nameAr,
    required String phone,
    required String nationalId,
    required String carLicense,
    required String personalLicense,
    List<String> favoritePlaceIds = const [],
  });

  /// Backfills missing [isActive] / [nameEn] / [nameAr] on legacy driver docs.
  /// Returns how many documents were updated.
  Future<int> fixLegacyDriverDocuments();
}
