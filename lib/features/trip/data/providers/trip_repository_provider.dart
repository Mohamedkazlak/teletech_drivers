import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/network/network_providers.dart';
import 'package:teletech_drivers/features/trip/data/datasources/api_trip_remote_data_source.dart';
import 'package:teletech_drivers/features/trip/data/datasources/trip_remote_data_source.dart';
import 'package:teletech_drivers/features/trip/data/repositories/api_trip_repository.dart';
import 'package:teletech_drivers/features/trip/domain/repositories/trip_repository.dart';

/// Dependency Injection: Riverpod.
final tripRemoteDataSourceProvider = Provider<TripRemoteDataSource>((ref) {
  return ApiTripRemoteDataSource(apiClient: ref.watch(apiClientProvider));
});

/// Dependency Injection: Riverpod.
final tripRepositoryProvider = Provider<TripRepository>((ref) {
  final repository = ApiTripRepository(
    dataSource: ref.watch(tripRemoteDataSourceProvider),
    failureMapper: ref.watch(apiFailureMapperProvider),
  );
  ref.onDispose(repository.dispose);
  return repository;
});
