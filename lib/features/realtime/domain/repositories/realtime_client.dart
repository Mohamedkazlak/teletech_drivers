import 'package:teletech_drivers/features/realtime/domain/entities/realtime_connection.dart';
import 'package:teletech_drivers/features/realtime/domain/entities/realtime_event.dart';

/// Repository: a Reverb-compatible socket. Presentation listens; it does not open sockets.
abstract interface class RealtimeClient {
  bool get isEnabled;

  Stream<RealtimeConnection> get connection;

  Stream<RealtimeEvent> get events;

  Future<void> connect({required List<String> channels});

  Future<void> reconnect();

  Future<void> disconnect();
}
