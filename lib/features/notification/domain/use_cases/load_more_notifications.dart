import 'package:teletech_drivers/features/notification/domain/repositories/notification_repository.dart';

class LoadMoreNotifications {
  const LoadMoreNotifications(this._repository);

  final NotificationRepository _repository;

  void call() => _repository.showMore();
}
