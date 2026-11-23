import 'package:dio/dio.dart';
import 'package:teletech_drivers/features/notification/domain/entities/app_notification.dart';
import 'package:teletech_drivers/features/notification/domain/entities/notification_page.dart';

/// Remote notification API.
abstract interface class NotificationRemoteDataSource {
  Future<NotificationPage> list({
    required int perPage,
    CancelToken? cancelToken,
  });

  Future<int> unreadCount({CancelToken? cancelToken});

  Future<AppNotification> markRead(String id);

  Future<int> markAllRead();
}
