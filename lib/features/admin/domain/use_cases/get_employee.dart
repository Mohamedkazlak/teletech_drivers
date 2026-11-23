import 'package:teletech_drivers/features/admin/domain/repositories/employee_repository.dart';
import 'package:teletech_drivers/features/auth/domain/entities/app_user.dart';

class GetEmployeeUseCase {
  const GetEmployeeUseCase(this._repository);

  final EmployeeRepository _repository;

  Future<AppUser> call(String employeeId) =>
      _repository.getEmployee(employeeId);
}
