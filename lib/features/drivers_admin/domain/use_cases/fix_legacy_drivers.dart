import 'package:teletech_drivers/features/drivers_admin/domain/repositories/driver_repository.dart';

class FixLegacyDriversUseCase {
  const FixLegacyDriversUseCase(this._repository);

  final DriverRepository _repository;

  Future<int> call() => _repository.fixLegacyDriverDocuments();
}
