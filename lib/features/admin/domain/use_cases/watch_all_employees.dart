import 'package:teletech_drivers/features/admin/domain/repositories/employee_repository.dart';
import 'package:teletech_drivers/features/auth/domain/entities/app_user.dart';

class WatchAllEmployeesUseCase {
  const WatchAllEmployeesUseCase(this._repository);

  final EmployeeRepository _repository;

  Stream<List<AppUser>> call() => _repository.watchAllEmployees();
}
