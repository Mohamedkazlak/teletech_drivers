import 'package:teletech_drivers/features/admin/domain/repositories/employee_repository.dart';
import 'package:teletech_drivers/features/auth/domain/entities/branch.dart';

class CreateEmployeeUseCase {
  const CreateEmployeeUseCase(this._repository);

  final EmployeeRepository _repository;

  Future<void> call({
    required String nameEn,
    required String nameAr,
    required String email,
    required String password,
    required String phone,
    required Branch branch,
  }) {
    return _repository.createEmployee(
      nameEn: nameEn,
      nameAr: nameAr,
      email: email,
      password: password,
      phone: phone,
      branch: branch,
    );
  }
}
