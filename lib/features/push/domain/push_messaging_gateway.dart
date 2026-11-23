import 'package:teletech_drivers/features/push/domain/entities/push_message.dart';

/// The FCM plugin, behind an interface so tests never touch Firebase.
abstract interface class PushMessagingGateway {
  bool get isEnabled;

  Future<void> prepare({
    required String channelName,
    required String channelDescription,
  });

  /// On iOS this waits for the APNs token, then registers with FCM.
  /// The value is the Firebase Installation ID.
  Future<String?> currentToken();

  /// Fires when FCM issues or rotates the installation id.
  Stream<String> get tokenRefresh;

  Stream<PushMessage> get foregroundMessages;

  Stream<PushMessage> get openedMessages;

  Future<PushMessage?> initialMessage();

  Future<void> showForeground(PushMessage message);
}
