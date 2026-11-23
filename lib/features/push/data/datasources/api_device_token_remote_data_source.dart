import 'package:teletech_drivers/core/constants/api_json_keys.dart';
import 'package:teletech_drivers/core/constants/api_paths.dart';
import 'package:teletech_drivers/core/network/api_client.dart';
import 'package:teletech_drivers/features/push/data/datasources/device_token_remote_data_source.dart';
import 'package:teletech_drivers/features/push/domain/entities/device_platform.dart';

class ApiDeviceTokenRemoteDataSource implements DeviceTokenRemoteDataSource {
  ApiDeviceTokenRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<void> register({
    required String token,
    required DevicePlatform platform,
    required String locale,
  }) async {
    await apiClient.post(
      ApiPaths.deviceTokens,
      data: {
        ApiJsonKeys.token: token,
        ApiJsonKeys.platform: platform.wireValue,
      },
      headers: {'Accept-Language': locale},
    );
  }

  @override
  Future<void> remove(String token) async {
    await apiClient.delete(
      ApiPaths.deviceTokens,
      data: {ApiJsonKeys.token: token},
    );
  }
}
