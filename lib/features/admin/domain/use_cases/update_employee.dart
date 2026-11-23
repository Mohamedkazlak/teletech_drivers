import 'package:teletech_drivers/features/admin/domain/repositories/employee_repository.dart';
import 'package:teletech_drivers/features/auth/domain/entities/branch.dart';

class UpdateEmployeeUseCase {
  const UpdateEmployeeUseCase(this._repository);

  final EmployeeRepository _repository;

  Future<void> call({
    required String employeeId,
    required String nameEn,
    required String nameAr,
    required String phone,
    required Branch branch,
  }) {
    return _repository.updateEmployee(
      employeeId: employeeId,
      nameEn: nameEn,
      nameAr: nameAr,
      phone: phone,
      branch: branch,
    );
  }
}
