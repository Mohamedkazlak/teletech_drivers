import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:teletech_drivers/features/push/domain/entities/device_platform.dart';
import 'package:teletech_drivers/features/push/domain/entities/push_message.dart';
import 'package:teletech_drivers/features/push/domain/push_messaging_gateway.dart';
import 'package:teletech_drivers/features/push/domain/push_registrar.dart';
import 'package:teletech_drivers/features/push/domain/repositories/device_token_repository.dart';

void main() {
  test('registers the token and deletes that token on logout', () async {
    final messaging = _FakeMessaging(token: 'tok-1');
    final tokens = _FakeTokens();
    final registrar = PushRegistrar(messaging: messaging, tokens: tokens);

    await registrar.sync(platform: DevicePlatform.ios, locale: 'ar');

    expect(tokens.registrations, hasLength(1));
    expect(tokens.registrations.single.token, 'tok-1');
    expect(tokens.registrations.single.platform, DevicePlatform.ios);
    expect(tokens.registrations.single.locale, 'ar');

    await registrar.onTokenRefreshed(
      'tok-2',
      platform: DevicePlatform.ios,
      locale: 'en',
    );
    await registrar.unregister();

    expect(tokens.removed, ['tok-2']);
  });

  test(
    'does not register when messaging is disabled or the token is missing',
    () async {
      final disabled = PushRegistrar(
        messaging: _FakeMessaging(token: 'tok', enabled: false),
        tokens: _FakeTokens(),
      );
      await disabled.sync(platform: DevicePlatform.android, locale: 'en');
      await disabled.unregister();

      final missing = _FakeTokens();
      final registrar = PushRegistrar(
        messaging: _FakeMessaging(),
        tokens: missing,
      );
      await registrar.sync(platform: DevicePlatform.android, locale: 'en');
      await registrar.unregister();

      expect(missing.registrations, isEmpty);
      expect(missing.removed, isEmpty);
    },
  );

  test('a token that arrives after logout is not kept', () async {
    final messaging = _FakeMessaging()..pendingToken = Completer<String?>();
    final tokens = _FakeTokens();
    final registrar = PushRegistrar(messaging: messaging, tokens: tokens);

    final syncing = registrar.sync(
      platform: DevicePlatform.android,
      locale: 'en',
    );
    await registrar.unregister();
    messaging.pendingToken!.complete('late');
    await syncing;

    expect(tokens.registrations, isEmpty);
    expect(tokens.removed, isEmpty);
  });
}

final class _Registration {
  const _Registration(this.token, this.platform, this.locale);

  final String token;
  final DevicePlatform platform;
  final String locale;
}

final class _FakeTokens implements DeviceTokenRepository {
  final registrations = <_Registration>[];
  final removed = <String>[];

  @override
  Future<void> register({
    required String token,
    required DevicePlatform platform,
    required String locale,
  }) async {
    registrations.add(_Registration(token, platform, locale));
  }

  @override
  Future<void> remove(String token) async {
    removed.add(token);
  }
}

final class _FakeMessaging implements PushMessagingGateway {
  _FakeMessaging({this.token, this.enabled = true});

  final bool enabled;
  String? token;
  Completer<String?>? pendingToken;

  @override
  bool get isEnabled => enabled;

  @override
  Future<void> prepare({
    required String channelName,
    required String channelDescription,
  }) async {}

  @override
  Future<String?> currentToken() {
    final pending = pendingToken;
    if (pending != null) return pending.future;
    return Future<String?>.value(token);
  }

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
