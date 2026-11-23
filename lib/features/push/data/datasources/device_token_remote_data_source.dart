import 'package:teletech_drivers/features/push/domain/entities/device_platform.dart';

abstract interface class DeviceTokenRemoteDataSource {
  Future<void> register({
    required String token,
    required DevicePlatform platform,
    required String locale,
  });

  Future<void> remove(String token);
}
