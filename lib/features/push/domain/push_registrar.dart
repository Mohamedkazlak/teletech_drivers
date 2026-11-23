import 'package:teletech_drivers/features/push/domain/entities/device_platform.dart';
import 'package:teletech_drivers/features/push/domain/push_messaging_gateway.dart';
import 'package:teletech_drivers/features/push/domain/repositories/device_token_repository.dart';

/// Registers the current FCM token and removes it on logout.
class PushRegistrar {
  PushRegistrar({required this.messaging, required this.tokens});

  final PushMessagingGateway messaging;
  final DeviceTokenRepository tokens;

  String? _token;
  var _generation = 0;

  Future<void> sync({
    required DevicePlatform platform,
    required String locale,
  }) async {
    if (!messaging.isEnabled) return;
    final generation = ++_generation;
    final token = await messaging.currentToken();
    if (generation != _generation || token == null || token.isEmpty) return;
    await tokens.register(token: token, platform: platform, locale: locale);
    if (generation != _generation) {
      await tokens.remove(token);
      return;
    }
    _token = token;
  }

  Future<void> onTokenRefreshed(
    String token, {
    required DevicePlatform platform,
    required String locale,
  }) async {
    if (!messaging.isEnabled || token.isEmpty) return;
    final generation = _generation;
    await tokens.register(token: token, platform: platform, locale: locale);
    if (generation != _generation) {
      await tokens.remove(token);
      return;
    }
    _token = token;
  }

  Future<void> unregister() async {
    _generation++;
    final token = _token;
    _token = null;
    if (token == null || token.isEmpty) return;
    await tokens.remove(token);
  }
}
