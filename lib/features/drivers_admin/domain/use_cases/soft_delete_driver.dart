import 'package:teletech_drivers/features/drivers_admin/domain/repositories/driver_repository.dart';

class SoftDeleteDriverUseCase {
  const SoftDeleteDriverUseCase(this._repository);

  final DriverRepository _repository;

  Future<void> call({
    required String driverId,
    required String deletedBy,
  }) {
    return _repository.softDeleteDriver(
      driverId: driverId,
      deletedBy: deletedBy,
    );
  }
}
