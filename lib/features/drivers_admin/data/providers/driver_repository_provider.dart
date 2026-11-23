import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/network/network_providers.dart';
import 'package:teletech_drivers/features/auth/data/providers/auth_repository_provider.dart';
import 'package:teletech_drivers/features/auth/data/repositories/api_auth_repository.dart';
import 'package:teletech_drivers/features/auth/domain/entities/user_role.dart';
import 'package:teletech_drivers/features/drivers_admin/data/datasources/api_driver_remote_data_source.dart';
import 'package:teletech_drivers/features/drivers_admin/data/datasources/driver_remote_data_source.dart';
import 'package:teletech_drivers/features/drivers_admin/data/repositories/api_driver_repository.dart';
import 'package:teletech_drivers/features/drivers_admin/domain/repositories/driver_repository.dart';

/// Dependency Injection: Riverpod.
final driverRemoteDataSourceProvider = Provider<DriverRemoteDataSource>((ref) {
  return ApiDriverRemoteDataSource(apiClient: ref.watch(apiClientProvider));
});

/// Dependency Injection: Riverpod.
final driverRepositoryProvider = Provider<DriverRepository>((ref) {
  final auth = ref.watch(authRepositoryProvider);
  final repository = ApiDriverRepository(
    dataSource: ref.watch(driverRemoteDataSourceProvider),
    failureMapper: ref.watch(apiFailureMapperProvider),
    includeDeleted: () {
      if (auth is! ApiAuthRepository) return false;
      return auth.currentUser?.role == UserRole.admin;
    },
  );
  ref.onDispose(repository.dispose);
  return repository;
});
