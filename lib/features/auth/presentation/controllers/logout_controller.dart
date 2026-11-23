import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/features/auth/presentation/providers/auth_providers.dart';
import 'package:teletech_drivers/features/push/presentation/push_session.dart';
import 'package:teletech_drivers/features/tracking/presentation/controllers/location_tracking_controller.dart';

/// Stops live tracking, removes the FCM token, then signs out. The session
/// ends locally even when `POST /auth/logout` fails.
final logoutControllerProvider = NotifierProvider<LogoutController, bool>(
  LogoutController.new,
);

class LogoutController extends Notifier<bool> {
  @override
  bool build() => false;

  Future<void> signOut() async {
    if (state) return;
    state = true;
    try {
      await ref
          .read(locationTrackingControllerProvider.notifier)
          .stopIfNeeded();
      await ref.read(pushSessionProvider.notifier).unregister();
      await ref
          .read(sessionSigningOutProvider.notifier)
          .run(() => ref.read(signOutUseCaseProvider)());
    } finally {
      if (ref.mounted) state = false;
    }
  }
}
