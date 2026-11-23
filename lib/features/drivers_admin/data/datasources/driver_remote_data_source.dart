import 'package:teletech_drivers/features/auth/data/models/user_dto.dart';
import 'package:teletech_drivers/features/drivers_admin/data/models/driver_completed_trip_dto.dart';

/// Drivers REST API.
abstract interface class DriverRemoteDataSource {
  Future<List<UserDto>> listDrivers({
    bool includeDeleted = false,
    String? attendance,
  });

  /// Completed trips for one driver (`period` + `date`, or all).
  Future<List<DriverCompletedTripDto>> listDriverTrips(
    String driverId, {
    String? period,
    String? date,
  });

  Future<UserDto> getDriver(String driverId);

  Future<UserDto> createDriver(Map<String, dynamic> body);

  Future<UserDto> updateDriver({
    required String driverId,
    required Map<String, dynamic> body,
  });

  Future<UserDto> softDeleteDriver(String driverId);

  Future<UserDto> restoreDriver(String driverId);
}
