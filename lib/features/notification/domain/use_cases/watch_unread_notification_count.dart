import 'package:teletech_drivers/features/notification/domain/repositories/notification_repository.dart';

class WatchUnreadNotificationCount {
  const WatchUnreadNotificationCount(this._repository);

  final NotificationRepository _repository;

  Stream<int> call() => _repository.watchUnreadCount();
}
