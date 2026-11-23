import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/network/network_providers.dart';
import 'package:teletech_drivers/features/admin/data/datasources/api_employee_remote_data_source.dart';
import 'package:teletech_drivers/features/admin/data/datasources/employee_remote_data_source.dart';
import 'package:teletech_drivers/features/admin/data/repositories/api_employee_repository.dart';
import 'package:teletech_drivers/features/admin/domain/repositories/employee_repository.dart';
import 'package:teletech_drivers/features/auth/data/providers/auth_repository_provider.dart';
import 'package:teletech_drivers/features/auth/data/repositories/api_auth_repository.dart';
import 'package:teletech_drivers/features/auth/domain/entities/user_role.dart';

/// Dependency Injection: Riverpod.
final employeeRemoteDataSourceProvider = Provider<EmployeeRemoteDataSource>((
  ref,
) {
  return ApiEmployeeRemoteDataSource(apiClient: ref.watch(apiClientProvider));
});

/// Dependency Injection: Riverpod.
final employeeRepositoryProvider = Provider<EmployeeRepository>((ref) {
  final auth = ref.watch(authRepositoryProvider);
  final repository = ApiEmployeeRepository(
    dataSource: ref.watch(employeeRemoteDataSourceProvider),
    failureMapper: ref.watch(apiFailureMapperProvider),
    includeDeleted: () {
      if (auth is! ApiAuthRepository) return false;
      return auth.currentUser?.role == UserRole.admin;
    },
  );
  ref.onDispose(repository.dispose);
  return repository;
});
