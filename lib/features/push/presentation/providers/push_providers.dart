import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/network/network_providers.dart';
import 'package:teletech_drivers/features/push/data/datasources/api_device_token_remote_data_source.dart';
import 'package:teletech_drivers/features/push/data/datasources/device_token_remote_data_source.dart';
import 'package:teletech_drivers/features/push/data/disabled_push_messaging_gateway.dart';
import 'package:teletech_drivers/features/push/data/repositories/api_device_token_repository.dart';
import 'package:teletech_drivers/features/push/domain/push_messaging_gateway.dart';
import 'package:teletech_drivers/features/push/domain/repositories/device_token_repository.dart';

/// Dependency Injection: Riverpod. [main] replaces this when Firebase starts.
final pushMessagingGatewayProvider = Provider<PushMessagingGateway>((ref) {
  return const DisabledPushMessagingGateway();
});

final deviceTokenRemoteDataSourceProvider =
    Provider<DeviceTokenRemoteDataSource>((ref) {
      return ApiDeviceTokenRemoteDataSource(
        apiClient: ref.watch(apiClientProvider),
      );
    });

/// Dependency Injection: Riverpod.
final deviceTokenRepositoryProvider = Provider<DeviceTokenRepository>((ref) {
  return ApiDeviceTokenRepository(
    dataSource: ref.watch(deviceTokenRemoteDataSourceProvider),
    failureMapper: ref.watch(apiFailureMapperProvider),
  );
});
