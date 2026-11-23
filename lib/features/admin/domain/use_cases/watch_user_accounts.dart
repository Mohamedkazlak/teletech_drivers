import 'package:teletech_drivers/features/admin/domain/repositories/user_account_repository.dart';
import 'package:teletech_drivers/features/auth/domain/entities/app_user.dart';

class WatchUserAccountsUseCase {
  const WatchUserAccountsUseCase(this._repository);

  final UserAccountRepository _repository;

  Stream<List<AppUser>> call() => _repository.watchAllUsers();
}
