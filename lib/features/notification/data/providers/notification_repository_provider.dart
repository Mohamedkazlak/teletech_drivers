import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/network/network_providers.dart';
import 'package:teletech_drivers/features/notification/data/datasources/api_notification_remote_data_source.dart';
import 'package:teletech_drivers/features/notification/data/datasources/notification_remote_data_source.dart';
import 'package:teletech_drivers/features/notification/data/repositories/api_notification_repository.dart';
import 'package:teletech_drivers/features/notification/domain/repositories/notification_repository.dart';

/// Dependency Injection: Riverpod.
final notificationRemoteDataSourceProvider =
    Provider<NotificationRemoteDataSource>((ref) {
      return ApiNotificationRemoteDataSource(
        apiClient: ref.watch(apiClientProvider),
      );
    });

/// Dependency Injection: Riverpod.
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final repository = ApiNotificationRepository(
    dataSource: ref.watch(notificationRemoteDataSourceProvider),
    failureMapper: ref.watch(apiFailureMapperProvider),
  );
  ref.onDispose(repository.dispose);
  return repository;
});
