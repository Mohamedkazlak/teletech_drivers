import 'package:teletech_drivers/features/auth/domain/entities/user_role.dart';
import 'package:teletech_drivers/features/notification/domain/entities/app_notification.dart';
import 'package:teletech_drivers/features/notification/presentation/notification_destination.dart';
import 'package:teletech_drivers/features/push/domain/entities/push_message.dart';

/// Strategy: the same screen map as an in-app notification tap.
String? pushLocation({required UserRole role, required PushMessage message}) {
  return notificationLocation(
    role: role,
    notification: AppNotification(
      id: message.notificationId,
      type: message.type,
      titleKey: '',
      bodyKey: '',
      params: const {},
      createdAt: DateTime.utc(2026),
      tripRequestId: message.tripRequestId,
      tripId: message.tripId,
    ),
  );
}
