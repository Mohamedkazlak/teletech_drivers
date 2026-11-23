import 'package:teletech_drivers/features/auth/data/models/auth_token_dto.dart';
import 'package:teletech_drivers/features/auth/data/models/user_dto.dart';
import 'package:teletech_drivers/features/auth/domain/entities/branch.dart';

/// Remote auth API (Sanctum).
abstract interface class AuthRemoteDataSource {
  Future<AuthTokenDto> login({
    required String email,
    required String password,
  });

  Future<AuthTokenDto> register({
    required String nameEn,
    required String nameAr,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String phone,
    required Branch branch,
  });

  Future<void> logout();

  /// Returns the updated account. `must_change_password` is false after success.
  Future<UserDto> changePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  });

  Future<UserDto> getMe();

  /// PATCH body. Only keys in [changes] are sent. Null values are included.
  Future<UserDto> updateMe(Map<String, Object?> changes);
}
