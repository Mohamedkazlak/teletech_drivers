import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/network/api_client.dart';
import 'package:teletech_drivers/core/network/api_failure_mapper.dart';
import 'package:teletech_drivers/core/network/secure_token_storage.dart';
import 'package:teletech_drivers/core/network/token_storage.dart';

/// Dependency Injection: Riverpod.
final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return SecureTokenStorage();
});

/// Dependency Injection: Riverpod.
final apiFailureMapperProvider = Provider<ApiFailureMapper>((ref) {
  return const ApiFailureMapper();
});

/// Dependency Injection: Riverpod.
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(tokenStorage: ref.watch(tokenStorageProvider));
});
