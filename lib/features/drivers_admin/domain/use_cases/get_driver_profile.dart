import 'package:teletech_drivers/features/drivers_admin/domain/entities/driver_profile.dart';
import 'package:teletech_drivers/features/drivers_admin/domain/repositories/driver_repository.dart';

class GetDriverProfileUseCase {
  const GetDriverProfileUseCase(this._repository);

  final DriverRepository _repository;

  Future<DriverProfile> call(String driverId) =>
      _repository.getDriverProfile(driverId);
}
