import 'package:teletech_drivers/features/admin/domain/repositories/employee_repository.dart';

class SoftDeleteEmployeeUseCase {
  const SoftDeleteEmployeeUseCase(this._repository);

  final EmployeeRepository _repository;

  Future<void> call({
    required String employeeId,
    required String deletedBy,
  }) {
    return _repository.softDeleteEmployee(
      employeeId: employeeId,
      deletedBy: deletedBy,
    );
  }
}
