import 'package:teletech_drivers/features/admin/domain/repositories/user_account_repository.dart';

class ResetUserPasswordUseCase {
  const ResetUserPasswordUseCase(this._repository);

  final UserAccountRepository _repository;

  Future<void> call({required String userId, required String password}) {
    return _repository.resetPassword(userId: userId, password: password);
  }
}
