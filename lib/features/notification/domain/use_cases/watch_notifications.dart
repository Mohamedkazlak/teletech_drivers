import 'package:teletech_drivers/features/notification/domain/entities/notification_page.dart';
import 'package:teletech_drivers/features/notification/domain/repositories/notification_repository.dart';

class WatchNotifications {
  const WatchNotifications(this._repository);

  final NotificationRepository _repository;

  Stream<NotificationPage> call() => _repository.watchInbox();
}
