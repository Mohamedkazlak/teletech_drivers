import 'package:teletech_drivers/features/notification/domain/entities/app_notification.dart';
import 'package:teletech_drivers/features/notification/domain/repositories/notification_repository.dart';

class MarkNotificationRead {
  const MarkNotificationRead(this._repository);

  final NotificationRepository _repository;

  Future<AppNotification> call(String id) => _repository.markRead(id);
}
