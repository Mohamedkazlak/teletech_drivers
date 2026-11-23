import 'package:teletech_drivers/features/admin/domain/repositories/employee_repository.dart';

class SetEmployeeActiveUseCase {
  const SetEmployeeActiveUseCase(this._repository);

  final EmployeeRepository _repository;

  Future<void> call({
    required String employeeId,
    required bool isActive,
  }) {
    return _repository.setEmployeeActive(
      employeeId: employeeId,
      isActive: isActive,
    );
  }
}
