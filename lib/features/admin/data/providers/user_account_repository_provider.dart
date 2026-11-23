import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/network/network_providers.dart';
import 'package:teletech_drivers/features/admin/data/datasources/api_user_account_remote_data_source.dart';
import 'package:teletech_drivers/features/admin/data/datasources/user_account_remote_data_source.dart';
import 'package:teletech_drivers/features/admin/data/repositories/api_user_account_repository.dart';
import 'package:teletech_drivers/features/admin/domain/repositories/user_account_repository.dart';

/// Dependency Injection: Riverpod.
final userAccountRemoteDataSourceProvider =
    Provider<UserAccountRemoteDataSource>((ref) {
      return ApiUserAccountRemoteDataSource(
        apiClient: ref.watch(apiClientProvider),
      );
    });

/// Dependency Injection: Riverpod.
final userAccountRepositoryProvider = Provider<UserAccountRepository>((ref) {
  final repository = ApiUserAccountRepository(
    dataSource: ref.watch(userAccountRemoteDataSourceProvider),
    failureMapper: ref.watch(apiFailureMapperProvider),
  );
  ref.onDispose(repository.dispose);
  return repository;
});
