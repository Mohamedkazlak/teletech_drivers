import 'package:teletech_drivers/features/auth/domain/entities/branch.dart';
import 'package:teletech_drivers/features/auth/domain/repositories/auth_repository.dart';

class CompleteEmployeeProfileUseCase {
  const CompleteEmployeeProfileUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call({
    required String uid,
    required String phone,
    required Branch branch,
  }) {
    return _repository.completeEmployeeProfile(
      uid: uid,
      phone: phone.trim(),
      branch: branch,
    );
  }
}
