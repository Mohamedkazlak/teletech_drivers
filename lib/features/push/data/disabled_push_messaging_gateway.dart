import 'package:teletech_drivers/features/push/domain/entities/push_message.dart';
import 'package:teletech_drivers/features/push/domain/push_messaging_gateway.dart';

/// Used when Firebase config is absent, and by tests.
final class DisabledPushMessagingGateway implements PushMessagingGateway {
  const DisabledPushMessagingGateway();

  @override
  bool get isEnabled => false;

  @override
  Future<void> prepare({
    required String channelName,
    required String channelDescription,
  }) async {}

  @override
  Future<String?> currentToken() async => null;

  @override
  Stream<String> get tokenRefresh => const Stream.empty();

  @override
  Stream<PushMessage> get foregroundMessages => const Stream.empty();

  @override
  Stream<PushMessage> get openedMessages => const Stream.empty();

  @override
  Future<PushMessage?> initialMessage() async => null;

  @override
  Future<void> showForeground(PushMessage message) async {}
}
