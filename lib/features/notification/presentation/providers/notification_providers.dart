import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/errors/failures.dart';
import 'package:teletech_drivers/features/auth/presentation/providers/auth_bound_stream.dart';
import 'package:teletech_drivers/features/notification/data/providers/notification_repository_provider.dart';
import 'package:teletech_drivers/features/notification/domain/entities/notification_page.dart';
import 'package:teletech_drivers/features/notification/domain/use_cases/load_more_notifications.dart';
import 'package:teletech_drivers/features/notification/domain/use_cases/mark_all_notifications_read.dart';
import 'package:teletech_drivers/features/notification/domain/use_cases/mark_notification_read.dart';
import 'package:teletech_drivers/features/notification/domain/use_cases/watch_notifications.dart';
import 'package:teletech_drivers/features/notification/domain/use_cases/watch_unread_notification_count.dart';

final watchUnreadNotificationCountProvider =
    Provider<WatchUnreadNotificationCount>((ref) {
      return WatchUnreadNotificationCount(
        ref.watch(notificationRepositoryProvider),
      );
    });

final watchNotificationsProvider = Provider<WatchNotifications>((ref) {
  return WatchNotifications(ref.watch(notificationRepositoryProvider));
});

final markNotificationReadProvider = Provider<MarkNotificationRead>((ref) {
  return MarkNotificationRead(ref.watch(notificationRepositoryProvider));
});

final markAllNotificationsReadProvider = Provider<MarkAllNotificationsRead>((
  ref,
) {
  return MarkAllNotificationsRead(ref.watch(notificationRepositoryProvider));
});

final loadMoreNotificationsProvider = Provider<LoadMoreNotifications>((ref) {
  return LoadMoreNotifications(ref.watch(notificationRepositoryProvider));
});

/// Observer: unread badge. Polls only while a session is active and the bell
/// is on screen.
final unreadNotificationCountProvider = StreamProvider.autoDispose<int>((ref) {
  return authBoundStream(
    ref,
    whenSignedOut: 0,
    create: (_) => ref.watch(watchUnreadNotificationCountProvider)(),
  );
}, retry: (_, _) => null);

/// Observer: inbox. Polls while the notifications screen is open.
final notificationInboxProvider = StreamProvider.autoDispose<NotificationPage>((
  ref,
) {
  return authBoundStream(
    ref,
    whenSignedOut: const NotificationPage(items: [], total: 0),
    create: (_) => ref.watch(watchNotificationsProvider)(),
  );
}, retry: (_, _) => null);

/// Loading and failure for mark-read actions.
final class NotificationActionState extends Equatable {
  const NotificationActionState({this.isLoading = false, this.failure});

  final bool isLoading;
  final Failure? failure;

  @override
  List<Object?> get props => [isLoading, failure];
}

/// Dependency Injection: Riverpod.
final notificationActionsProvider =
    NotifierProvider.autoDispose<
      NotificationActionsController,
      NotificationActionState
    >(NotificationActionsController.new);

class NotificationActionsController extends Notifier<NotificationActionState> {
  @override
  NotificationActionState build() => const NotificationActionState();

  Future<bool> markRead(String id) =>
      _run(() => ref.read(markNotificationReadProvider)(id));

  Future<bool> markAll() =>
      _run(() => ref.read(markAllNotificationsReadProvider)());

  void loadMore() {
    ref.read(loadMoreNotificationsProvider)();
  }

  Future<bool> _run(Future<Object?> Function() action) async {
    if (state.isLoading) return false;
    state = const NotificationActionState(isLoading: true);
    try {
      await action();
      if (!ref.mounted) return false;
      state = const NotificationActionState();
      return true;
    } on Failure catch (failure) {
      if (!ref.mounted) return false;
      state = NotificationActionState(failure: failure);
      return false;
    } on Object {
      if (!ref.mounted) return false;
      state = const NotificationActionState(failure: UnknownFailure());
      return false;
    }
  }
}
