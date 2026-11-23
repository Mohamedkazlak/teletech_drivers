import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/network/network_providers.dart';
import 'package:teletech_drivers/core/session/session_uid_source.dart';
import 'package:teletech_drivers/features/auth/data/datasources/api_auth_remote_data_source.dart';
import 'package:teletech_drivers/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:teletech_drivers/features/auth/data/repositories/api_auth_repository.dart';
import 'package:teletech_drivers/features/auth/domain/repositories/auth_repository.dart';

/// Dependency Injection: Riverpod.
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return ApiAuthRemoteDataSource(apiClient: ref.watch(apiClientProvider));
});

/// Dependency Injection: Riverpod.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final repository = ApiAuthRepository(
    dataSource: ref.watch(authRemoteDataSourceProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
    apiClient: ref.watch(apiClientProvider),
    failureMapper: ref.watch(apiFailureMapperProvider),
  );
  unawaited(repository.bootstrap());
  ref.onDispose(repository.dispose);
  return repository;
});

/// Exposes the signed-in user id to features that key requests by it.
final sessionUidSourceProvider = Provider<SessionUidSource>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository as SessionUidSource;
});
