import 'package:teletech_drivers/features/auth/domain/repositories/auth_repository.dart';

/// Changes the signed-in user's password without ending this session.
class ChangePasswordUseCase {
  const ChangePasswordUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) {
    return _repository.changePassword(
      currentPassword: currentPassword,
      password: password,
      passwordConfirmation: passwordConfirmation,
    );
  }
}
