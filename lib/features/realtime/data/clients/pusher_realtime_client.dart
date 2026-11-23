import 'dart:async';

import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import 'package:teletech_drivers/core/network/api_client.dart';
import 'package:teletech_drivers/features/realtime/data/clients/api_channel_authorizer.dart';
import 'package:teletech_drivers/features/realtime/domain/entities/realtime_connection.dart';
import 'package:teletech_drivers/features/realtime/domain/entities/realtime_event.dart';
import 'package:teletech_drivers/features/realtime/domain/repositories/realtime_client.dart';

/// Repository: Reverb over the Pusher protocol (dart_pusher_channels).
final class PusherRealtimeClient implements RealtimeClient {
  PusherRealtimeClient({
    required this.api,
    required this.host,
    required this.port,
    required this.appKey,
    required this.useTls,
  });

  final ApiClient api;
  final String host;
  final int port;
  final String appKey;
  final bool useTls;

  final StreamController<RealtimeConnection> _connection =
      StreamController<RealtimeConnection>.broadcast();
  final StreamController<RealtimeEvent> _events =
      StreamController<RealtimeEvent>.broadcast();

  PusherChannelsClient? _client;
  StreamSubscription<PusherChannelsClientLifeCycleState>? _lifecycle;
  StreamSubscription<PusherChannelsReadEvent>? _incoming;
  List<String> _channels = const [];
  Future<void> _gate = Future<void>.value();

  @override
  bool get isEnabled => true;

  @override
  Stream<RealtimeConnection> get connection => _connection.stream;

  @override
  Stream<RealtimeEvent> get events => _events.stream;

  @override
  Future<void> connect({required List<String> channels}) {
    return _serialized(() async {
      _channels = List<String>.unmodifiable(channels);
      await _open();
    });
  }

  @override
  Future<void> reconnect() {
    return _serialized(() async {
      if (_channels.isEmpty) return;
      await _open();
    });
  }

  @override
  Future<void> disconnect() {
    return _serialized(() async {
      _channels = const [];
      await _closeClient();
      _emit(RealtimeConnection.disconnected);
    });
  }

  Future<void> _serialized(Future<void> Function() action) {
    final run = _gate.catchError((_) {}).then((_) => action());
    _gate = run;
    return run;
  }

  Future<void> _open() async {
    await _closeClient();
    if (_channels.isEmpty) return;
    _emit(RealtimeConnection.connecting);

    final client = PusherChannelsClient.websocket(
      options: PusherChannelsOptions.fromHost(
        scheme: useTls ? 'wss' : 'ws',
        host: host,
        key: appKey,
        port: port,
      ),
      connectionErrorHandler: (exception, stackTrace, refresh) {
        _emit(RealtimeConnection.disconnected);
        refresh();
      },
    );
    _client = client;
    final authorizer = ApiChannelAuthorizer(api);
    _lifecycle = client.lifecycleStream.listen((state) {
      _emit(_mapState(state));
      if (state == PusherChannelsClientLifeCycleState.establishedConnection) {
        _subscribe(client, authorizer);
      }
    });
    _incoming = client.eventStream.listen(_onIncoming);
    await client.connect();
  }

  void _subscribe(PusherChannelsClient client, ApiChannelAuthorizer authorizer) {
    for (final name in _channels) {
      client
          .privateChannel(name, authorizationDelegate: authorizer)
          .subscribe();
    }
  }

  void _onIncoming(PusherChannelsReadEvent event) {
    final name = event.name;
    if (name.isEmpty || name.startsWith('pusher:')) return;
    final data = event.tryGetDataAsMap();
    if (data == null) return;
    final id = data['id'];
    if (id is! String || id.isEmpty) return;
    final status = data['status'];
    final lat = data['lat'];
    final lng = data['lng'];
    final tripId = data['trip_id'];
    if (_events.isClosed) return;
    _events.add(
      RealtimeEvent(
        name: name,
        id: id,
        status: status is String ? status : '',
        tripId: tripId is String ? tripId : null,
        lat: lat is num ? lat.toDouble() : null,
        lng: lng is num ? lng.toDouble() : null,
      ),
    );
  }

  RealtimeConnection _mapState(PusherChannelsClientLifeCycleState state) {
    return switch (state) {
      PusherChannelsClientLifeCycleState.establishedConnection =>
        RealtimeConnection.connected,
      PusherChannelsClientLifeCycleState.pendingConnection ||
      PusherChannelsClientLifeCycleState.reconnecting =>
        RealtimeConnection.connecting,
      PusherChannelsClientLifeCycleState.inactive =>
        RealtimeConnection.connecting,
      _ => RealtimeConnection.disconnected,
    };
  }

  Future<void> _closeClient() async {
    await _lifecycle?.cancel();
    await _incoming?.cancel();
    _lifecycle = null;
    _incoming = null;
    final client = _client;
    _client = null;
    if (client == null) return;
    await client.disconnect();
    client.dispose();
  }

  void _emit(RealtimeConnection state) {
    if (_connection.isClosed) return;
    _connection.add(state);
  }
}
