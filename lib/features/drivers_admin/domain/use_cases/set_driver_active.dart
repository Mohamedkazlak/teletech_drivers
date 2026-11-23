import 'package:teletech_drivers/features/drivers_admin/domain/repositories/driver_repository.dart';

class SetDriverActiveUseCase {
  const SetDriverActiveUseCase(this._repository);

  final DriverRepository _repository;

  Future<void> call({required String driverId, required bool isActive}) {
    return _repository.setDriverActive(driverId: driverId, isActive: isActive);
  }
}
