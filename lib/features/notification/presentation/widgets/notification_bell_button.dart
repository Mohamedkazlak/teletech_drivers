import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/router/app_routes.dart';
import 'package:teletech_drivers/features/auth/presentation/providers/auth_providers.dart';
import 'package:teletech_drivers/features/notification/presentation/providers/notification_providers.dart';

/// App-bar bell. Hidden until a session exists. The badge follows the inbox poll.
class NotificationBellButton extends ConsumerWidget {
  const NotificationBellButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).asData?.value;
    if (user == null) return const SizedBox.shrink();
    return _Bell(rolePath: AppRoutes.notificationsPath(user.role));
  }
}

class _Bell extends ConsumerStatefulWidget {
  const _Bell({required this.rolePath});

  final String rolePath;

  @override
  ConsumerState<_Bell> createState() => _BellState();
}

/// Owns the unread subscription so leaving the tree stops the poll immediately.
/// Riverpod disposes autoDispose providers on a later turn, which leaves the
/// interval timer pending in widget tests.
class _BellState extends ConsumerState<_Bell> {
  StreamSubscription<int>? _subscription;
  var _count = 0;

  @override
  void initState() {
    super.initState();
    _subscription = ref.read(watchUnreadNotificationCountProvider)().listen((
      count,
    ) {
      if (!mounted) return;
      setState(() => _count = count);
    }, onError: (_, _) {});
  }

  @override
  void dispose() {
    final subscription = _subscription;
    _subscription = null;
    unawaited(subscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = _count > 99 ? '99+' : '$_count';

    return IconButton(
      tooltip: l10n.notificationsTitle,
      onPressed: () => context.push(widget.rolePath),
      icon: Badge(
        isLabelVisible: _count > 0,
        label: Text(label),
        child: const Icon(Icons.notifications_outlined),
      ),
    );
  }
}
