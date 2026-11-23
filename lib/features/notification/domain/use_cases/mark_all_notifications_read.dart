import 'package:teletech_drivers/features/notification/domain/repositories/notification_repository.dart';

class MarkAllNotificationsRead {
  const MarkAllNotificationsRead(this._repository);

  final NotificationRepository _repository;

  Future<int> call() => _repository.markAllRead();
}
