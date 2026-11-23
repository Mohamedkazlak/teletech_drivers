import 'package:teletech_drivers/features/auth/domain/entities/branch.dart';
import 'package:teletech_drivers/features/auth/domain/repositories/auth_repository.dart';

class RegisterEmployeeUseCase {
  const RegisterEmployeeUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call({
    required String name,
    required String nameAr,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String phone,
    required Branch branch,
  }) {
    return _repository.registerEmployee(
      name: name.trim(),
      nameAr: nameAr.trim(),
      email: email.trim().toLowerCase(),
      password: password,
      passwordConfirmation: passwordConfirmation,
      phone: phone.trim(),
      branch: branch,
    );
  }
}
