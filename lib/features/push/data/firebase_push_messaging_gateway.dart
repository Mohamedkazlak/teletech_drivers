import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:teletech_drivers/features/push/domain/entities/push_message.dart';
import 'package:teletech_drivers/features/push/domain/push_messaging_gateway.dart';

/// Android channel used by FCM (`channel_id`) and foreground local notifications.
const pushNotificationChannelId = 'trips';

/// FCM plus a local notification for Android foreground messages.
final class FirebasePushMessagingGateway implements PushMessagingGateway {
  FirebasePushMessagingGateway({
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
  }) : _messaging = messaging ?? FirebaseMessaging.instance,
       _local = localNotifications ?? FlutterLocalNotificationsPlugin();

  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _local;
  final _opened = StreamController<PushMessage>.broadcast();

  StreamSubscription<RemoteMessage>? _openedRemote;
  var _prepared = false;
  var _listening = false;
  var _initialRead = false;
  String _channelName = 'Trips';
  String _channelDescription = 'Trip assignments and request updates';

  @override
  bool get isEnabled => true;

  @override
  Future<void> prepare({
    required String channelName,
    required String channelDescription,
  }) async {
    _channelName = channelName;
    _channelDescription = channelDescription;
    _listenForOpens();
    if (_prepared) {
      await _createChannel();
      return;
    }
    await _local.initialize(
      settings: InitializationSettings(
        android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: const DarwinInitializationSettings(
          requestAlertPermission: false,
          requestSoundPermission: false,
          requestBadgePermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: _onLocalTap,
    );
    await _createChannel();
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    _prepared = true;
  }

  @override
  Future<String?> currentToken() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final apns = await _waitForApnsToken();
      if (apns == null) {
        debugPrint(
          'APNs token is not available yet; FCM registration was skipped.',
        );
        return null;
      }
    }

    final pending = Completer<String?>();
    final subscription = _messaging.onRegistered.listen((id) {
      if (!pending.isCompleted && id.isNotEmpty) pending.complete(id);
    });
    try {
      await _messaging.register();
      return await pending.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => null,
      );
    } catch (error) {
      debugPrint('FCM registration failed: $error');
      return null;
    } finally {
      await subscription.cancel();
    }
  }

  @override
  Stream<String> get tokenRefresh => _messaging.onRegistered;

  @override
  Stream<PushMessage> get foregroundMessages {
    return FirebaseMessaging.onMessage.expand((remote) sync* {
      final message = _messageFromRemote(remote);
      if (message != null) yield message;
    });
  }

  @override
  Stream<PushMessage> get openedMessages => _opened.stream;

  @override
  Future<PushMessage?> initialMessage() async {
    if (_initialRead) return null;
    _initialRead = true;
    final remote = await _messaging.getInitialMessage();
    if (remote != null) return _messageFromRemote(remote);
    final launch = await _local.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp != true) return null;
    return PushMessage.fromPayload(launch?.notificationResponse?.payload);
  }

  @override
  Future<void> showForeground(PushMessage message) async {
    if (defaultTargetPlatform != TargetPlatform.android || !_prepared) return;
    await _local.show(
      id: message.notificationId.hashCode & 0x7fffffff,
      title: message.title,
      body: message.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          pushNotificationChannelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: message.encode(),
    );
  }

  void dispose() {
    unawaited(_openedRemote?.cancel());
    unawaited(_opened.close());
  }

  void _listenForOpens() {
    if (_listening) return;
    _listening = true;
    _openedRemote = FirebaseMessaging.onMessageOpenedApp.listen((remote) {
      final message = _messageFromRemote(remote);
      if (message != null && !_opened.isClosed) _opened.add(message);
    });
  }

  void _onLocalTap(NotificationResponse response) {
    final message = PushMessage.fromPayload(response.payload);
    if (message != null && !_opened.isClosed) _opened.add(message);
  }

  Future<void> _createChannel() async {
    final android = _local
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.createNotificationChannel(
      AndroidNotificationChannel(
        pushNotificationChannelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
      ),
    );
  }

  Future<String?> _waitForApnsToken() async {
    for (var attempt = 0; attempt < 10; attempt++) {
      final token = await _messaging.getAPNSToken();
      if (token != null && token.isNotEmpty) return token;
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
    return null;
  }

  PushMessage? _messageFromRemote(RemoteMessage remote) {
    return PushMessage.fromData(
      remote.data,
      title: remote.notification?.title,
      body: remote.notification?.body,
    );
  }
}
