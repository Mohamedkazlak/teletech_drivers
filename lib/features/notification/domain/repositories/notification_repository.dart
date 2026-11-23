import 'package:teletech_drivers/features/notification/domain/entities/app_notification.dart';
import 'package:teletech_drivers/features/notification/domain/entities/notification_page.dart';

/// Repository: the signed-in user's notification inbox.
abstract interface class NotificationRepository {
  /// Observer: unread total, polled while the app is in the foreground.
  Stream<int> watchUnreadCount();

  /// Observer: the inbox, polled while a listener is attached.
  Stream<NotificationPage> watchInbox();

  Future<AppNotification> markRead(String id);

  /// Returns how many rows were newly marked read.
  Future<int> markAllRead();

  /// Asks the next inbox poll to include a larger page.
  void showMore();

  /// Fetches the badge and inbox again. Used when a push arrives.
  void refresh();

  void dispose();
}
