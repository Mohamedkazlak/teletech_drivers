import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/localization/locale_controller.dart';
import 'package:teletech_drivers/core/router/app_router.dart';
import 'package:teletech_drivers/core/router/app_routes.dart';
import 'package:teletech_drivers/features/auth/domain/entities/app_user.dart';
import 'package:teletech_drivers/features/auth/presentation/providers/auth_providers.dart';
import 'package:teletech_drivers/features/notification/data/providers/notification_repository_provider.dart';
import 'package:teletech_drivers/features/notification/presentation/providers/notification_providers.dart';
import 'package:teletech_drivers/features/push/domain/entities/device_platform.dart';
import 'package:teletech_drivers/features/push/domain/entities/push_message.dart';
import 'package:teletech_drivers/features/push/domain/push_destination.dart';
import 'package:teletech_drivers/features/push/domain/push_messaging_gateway.dart';
import 'package:teletech_drivers/features/push/domain/push_registrar.dart';
import 'package:teletech_drivers/features/push/presentation/providers/push_providers.dart';

/// Observer: registers the device token for the signed-in session and opens
/// the screen for a tapped push. Dependency Injection: Riverpod.
final pushSessionProvider = NotifierProvider<PushSession, void>(
  PushSession.new,
);

class PushSession extends Notifier<void> {
  PushRegistrar? _registrar;
  StreamSubscription<String>? _refreshSub;
  StreamSubscription<PushMessage>? _foregroundSub;
  StreamSubscription<PushMessage>? _openedSub;
  GoRouter? _router;
  VoidCallback? _routeListener;
  PushMessage? _pending;
  var _flushScheduled = false;
  var _initialHandled = false;

  @override
  void build() {
    ref.onDispose(_stop);
    final gateway = ref.watch(pushMessagingGatewayProvider);
    if (!gateway.isEnabled) return;

    _registrar ??= PushRegistrar(
      messaging: gateway,
      tokens: ref.read(deviceTokenRepositoryProvider),
    );

    final user = ref.watch(currentUserProvider).asData?.value;
    final locale = ref.watch(localeControllerProvider).languageCode;
    _listen(gateway);
    _watchRoutes();
    ref.listen(currentUserProvider, (_, _) => _scheduleFlush());

    if (user == null) return;
    unawaited(_sync(gateway, locale));
  }

  /// DELETE /device-tokens while the session token is still valid.
  Future<void> unregister() async {
    try {
      await _registrar?.unregister();
    } catch (error, stackTrace) {
      debugPrint('Device token removal failed: $error\n$stackTrace');
    }
  }

  Future<void> _sync(PushMessagingGateway gateway, String locale) async {
    final l10n = lookupAppLocalizations(Locale(locale));
    try {
      await gateway.prepare(
        channelName: l10n.notificationChannelTrips,
        channelDescription: l10n.notificationChannelTripsDescription,
      );
      await _registrar?.sync(platform: DevicePlatform.current, locale: locale);
      if (_initialHandled || !ref.mounted) return;
      _initialHandled = true;
      final initial = await gateway.initialMessage();
      if (initial != null) _queue(initial);
    } catch (error, stackTrace) {
      debugPrint('Push registration failed: $error\n$stackTrace');
    }
  }

  void _listen(PushMessagingGateway gateway) {
    _refreshSub ??= gateway.tokenRefresh.listen((token) {
      final user = ref.read(currentUserProvider).asData?.value;
      if (user == null) return;
      final locale = ref.read(localeControllerProvider).languageCode;
      unawaited(() async {
        try {
          await _registrar?.onTokenRefreshed(
            token,
            platform: DevicePlatform.current,
            locale: locale,
          );
        } catch (error, stackTrace) {
          debugPrint('Push token refresh failed: $error\n$stackTrace');
        }
      }());
    });
    _foregroundSub ??= gateway.foregroundMessages.listen((message) {
      unawaited(_onForeground(gateway, message));
    });
    _openedSub ??= gateway.openedMessages.listen(_queue);
  }

  Future<void> _onForeground(
    PushMessagingGateway gateway,
    PushMessage message,
  ) async {
    try {
      await gateway.showForeground(message);
    } catch (error, stackTrace) {
      debugPrint('Foreground notification failed: $error\n$stackTrace');
    }
    if (!ref.mounted) return;
    ref.read(notificationRepositoryProvider).refresh();
  }

  void _queue(PushMessage message) {
    _pending = message;
    _scheduleFlush();
  }

  void _watchRoutes() {
    if (_routeListener != null) return;
    final router = ref.read(appRouterProvider);
    _router = router;
    _routeListener = _scheduleFlush;
    router.routerDelegate.addListener(_routeListener!);
  }

  void _scheduleFlush() {
    if (_flushScheduled) return;
    _flushScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _flushScheduled = false;
      if (ref.mounted) _flush();
    });
  }

  void _flush() {
    final message = _pending;
    if (message == null || !ref.mounted) return;
    final user = ref.read(currentUserProvider).asData?.value;
    if (user == null) return;
    final router = ref.read(appRouterProvider);
    if (router.state.matchedLocation == AppRoutes.splash) return;
    _pending = null;
    unawaited(_open(user, message));
  }

  Future<void> _open(AppUser user, PushMessage message) async {
    try {
      await ref.read(markNotificationReadProvider)(message.notificationId);
    } catch (error, stackTrace) {
      debugPrint(
        'Could not mark the push notification read: $error\n$stackTrace',
      );
    }
    if (!ref.mounted) return;
    ref.read(notificationRepositoryProvider).refresh();
    final location = pushLocation(role: user.role, message: message);
    if (location == null || !ref.mounted) return;
    ref.read(appRouterProvider).push(location);
  }

  void _stop() {
    final listener = _routeListener;
    final router = _router;
    if (listener != null && router != null) {
      router.routerDelegate.removeListener(listener);
    }
    _routeListener = null;
    _router = null;
    unawaited(_refreshSub?.cancel());
    unawaited(_foregroundSub?.cancel());
    unawaited(_openedSub?.cancel());
    _refreshSub = null;
    _foregroundSub = null;
    _openedSub = null;
  }
}

/// Keeps push registration alive for the signed-in session.
void watchPushSession(WidgetRef ref) {
  ref.watch(pushSessionProvider);
}
