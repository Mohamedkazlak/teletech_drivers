import 'package:equatable/equatable.dart';
import 'package:teletech_drivers/features/notification/domain/entities/app_notification.dart';

/// First page of the signed-in user's notifications.
final class NotificationPage extends Equatable {
  const NotificationPage({required this.items, required this.total});

  final List<AppNotification> items;
  final int total;

  bool get canLoadMore => items.length < total && items.length < 100;

  @override
  List<Object?> get props => [items, total];
}
