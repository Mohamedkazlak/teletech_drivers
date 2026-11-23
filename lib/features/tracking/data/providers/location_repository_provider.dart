import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/network/network_providers.dart';
import 'package:teletech_drivers/features/tracking/data/datasources/api_location_remote_data_source.dart';
import 'package:teletech_drivers/features/tracking/data/datasources/location_remote_data_source.dart';
import 'package:teletech_drivers/features/tracking/data/repositories/api_location_repository.dart';
import 'package:teletech_drivers/features/tracking/domain/repositories/location_repository.dart';

/// Dependency Injection: Riverpod.
final locationRemoteDataSourceProvider = Provider<LocationRemoteDataSource>((
  ref,
) {
  return ApiLocationRemoteDataSource(apiClient: ref.watch(apiClientProvider));
});

/// Dependency Injection: Riverpod.
final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  final repository = ApiLocationRepository(
    dataSource: ref.watch(locationRemoteDataSourceProvider),
  );
  ref.onDispose(repository.dispose);
  return repository;
});
