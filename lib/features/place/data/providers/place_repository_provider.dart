import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/network/network_providers.dart';
import 'package:teletech_drivers/features/place/data/datasources/api_place_remote_data_source.dart';
import 'package:teletech_drivers/features/place/data/datasources/place_remote_data_source.dart';
import 'package:teletech_drivers/features/place/data/repositories/api_place_repository.dart';
import 'package:teletech_drivers/features/place/domain/repositories/place_repository.dart';

/// Dependency Injection: Riverpod.
final placeRemoteDataSourceProvider = Provider<PlaceRemoteDataSource>((ref) {
  return ApiPlaceRemoteDataSource(apiClient: ref.watch(apiClientProvider));
});

/// Dependency Injection: Riverpod.
final placeRepositoryProvider = Provider<PlaceRepository>((ref) {
  final repository = ApiPlaceRepository(
    dataSource: ref.watch(placeRemoteDataSourceProvider),
    failureMapper: ref.watch(apiFailureMapperProvider),
  );
  ref.onDispose(repository.dispose);
  return repository;
});
