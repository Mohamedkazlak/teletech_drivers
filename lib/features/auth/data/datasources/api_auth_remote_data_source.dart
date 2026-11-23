import 'package:teletech_drivers/core/constants/api_json_keys.dart';
import 'package:teletech_drivers/core/constants/api_paths.dart';
import 'package:teletech_drivers/core/network/api_client.dart';
import 'package:teletech_drivers/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:teletech_drivers/features/auth/data/models/auth_token_dto.dart';
import 'package:teletech_drivers/features/auth/data/models/user_dto.dart';
import 'package:teletech_drivers/features/auth/domain/entities/branch.dart';

class ApiAuthRemoteDataSource implements AuthRemoteDataSource {
  const ApiAuthRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<AuthTokenDto> login({
    required String email,
    required String password,
  }) async {
    final response = await apiClient.post(
      ApiPaths.authLogin,
      data: {ApiJsonKeys.email: email, ApiJsonKeys.password: password},
    );
    return AuthTokenDto.fromJson(_asMap(response.data));
  }

  @override
  Future<AuthTokenDto> register({
    required String nameEn,
    required String nameAr,
    required String email,
    required String password,
    required String passwordConfirmation,
    required String phone,
    required Branch branch,
  }) async {
    final response = await apiClient.post(
      ApiPaths.authRegister,
      data: {
        ApiJsonKeys.nameEn: nameEn,
        ApiJsonKeys.nameAr: nameAr,
        ApiJsonKeys.email: email,
        ApiJsonKeys.password: password,
        ApiJsonKeys.passwordConfirmation: passwordConfirmation,
        ApiJsonKeys.phone: phone,
        ApiJsonKeys.branch: branch.wireValue,
      },
    );
    return AuthTokenDto.fromJson(_asMap(response.data));
  }

  @override
  Future<void> logout() async {
    await apiClient.post(ApiPaths.authLogout);
  }

  @override
  Future<UserDto> changePassword({
    required String currentPassword,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await apiClient.post(
      ApiPaths.authChangePassword,
      data: {
        ApiJsonKeys.currentPassword: currentPassword,
        ApiJsonKeys.password: password,
        ApiJsonKeys.passwordConfirmation: passwordConfirmation,
      },
    );
    return UserDto.fromJson(_asMap(response.data));
  }

  @override
  Future<UserDto> getMe() async {
    final response = await apiClient.get(ApiPaths.authMe);
    return UserDto.fromJson(_asMap(response.data));
  }

  @override
  Future<UserDto> updateMe(Map<String, Object?> changes) async {
    final response = await apiClient.patch(ApiPaths.authMe, data: changes);
    return UserDto.fromJson(_asMap(response.data));
  }

  static Map<String, dynamic> _asMap(Object? data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const FormatException('Expected JSON object');
  }
}
