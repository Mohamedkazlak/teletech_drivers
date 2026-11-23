import 'package:teletech_drivers/features/auth/data/models/user_dto.dart';

abstract interface class UserAccountRemoteDataSource {
  Future<List<UserDto>> listUsers();

  Future<UserDto> resetPassword({
    required String userId,
    required String password,
  });
}
