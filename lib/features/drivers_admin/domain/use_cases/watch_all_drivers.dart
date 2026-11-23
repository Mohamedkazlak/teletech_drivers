import 'package:teletech_drivers/features/auth/domain/entities/app_user.dart';
import 'package:teletech_drivers/features/drivers_admin/domain/repositories/driver_repository.dart';

class WatchAllDriversUseCase {
  const WatchAllDriversUseCase(this._repository);

  final DriverRepository _repository;

  Stream<List<AppUser>> call() => _repository.watchAllDrivers();
}
