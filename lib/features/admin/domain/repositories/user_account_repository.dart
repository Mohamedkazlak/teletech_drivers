import 'package:teletech_drivers/features/auth/domain/entities/app_user.dart';

/// Repository: every account the system admin can reset.
abstract interface class UserAccountRepository {
  /// Observer: all non-deleted accounts, any role.
  Stream<List<AppUser>> watchAllUsers();

  /// Sets a temporary password. The account must change it on the next sign-in.
  Future<void> resetPassword({
    required String userId,
    required String password,
  });
}
