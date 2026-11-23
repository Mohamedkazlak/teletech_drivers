import 'package:teletech_drivers/features/push/domain/entities/device_platform.dart';

/// Repository: the signed-in user's FCM device token.
abstract interface class DeviceTokenRepository {
  Future<void> register({
    required String token,
    required DevicePlatform platform,
    required String locale,
  });

  Future<void> remove(String token);
}
