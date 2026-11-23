import 'package:teletech_drivers/core/constants/api_json_keys.dart';
import 'package:teletech_drivers/core/constants/api_paths.dart';
import 'package:teletech_drivers/core/network/api_client.dart';
import 'package:teletech_drivers/features/admin/data/datasources/user_account_remote_data_source.dart';
import 'package:teletech_drivers/features/auth/data/models/user_dto.dart';

class ApiUserAccountRemoteDataSource implements UserAccountRemoteDataSource {
  const ApiUserAccountRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<List<UserDto>> listUsers() {
    return apiClient.fetchAllPages(
      path: ApiPaths.users,
      mapItem: UserDto.fromJson,
    );
  }

  @override
  Future<UserDto> resetPassword({
    required String userId,
    required String password,
  }) async {
    final response = await apiClient.post(
      ApiPaths.resetUserPassword(userId),
      data: {
        ApiJsonKeys.password: password,
        ApiJsonKeys.passwordConfirmation: password,
      },
    );
    return UserDto.fromJson(_asMap(response.data));
  }

  static Map<String, dynamic> _asMap(Object? data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const FormatException('Expected JSON object');
  }
}
