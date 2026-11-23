import 'package:teletech_drivers/features/realtime/domain/entities/realtime_connection.dart';
import 'package:teletech_drivers/features/realtime/domain/entities/realtime_event.dart';
import 'package:teletech_drivers/features/realtime/domain/repositories/realtime_client.dart';

/// Used in tests and when no Reverb key is configured.
final class DisabledRealtimeClient implements RealtimeClient {
  const DisabledRealtimeClient();

  @override
  bool get isEnabled => false;

  @override
  Stream<RealtimeConnection> get connection => const Stream.empty();

  @override
  Stream<RealtimeEvent> get events => const Stream.empty();

  @override
  Future<void> connect({required List<String> channels}) async {}

  @override
  Future<void> reconnect() async {}

  @override
  Future<void> disconnect() async {}
}
