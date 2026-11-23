import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/network/network_providers.dart';
import 'package:teletech_drivers/features/trip_request/data/datasources/api_trip_request_remote_data_source.dart';
import 'package:teletech_drivers/features/trip_request/data/datasources/trip_request_remote_data_source.dart';
import 'package:teletech_drivers/features/trip_request/data/repositories/api_trip_request_repository.dart';
import 'package:teletech_drivers/features/trip_request/domain/repositories/trip_request_repository.dart';

/// Dependency Injection: Riverpod.
final tripRequestRemoteDataSourceProvider =
    Provider<TripRequestRemoteDataSource>((ref) {
      return ApiTripRequestRemoteDataSource(
        apiClient: ref.watch(apiClientProvider),
      );
    });

/// Dependency Injection: Riverpod.
final tripRequestRepositoryProvider = Provider<TripRequestRepository>((ref) {
  final repository = ApiTripRequestRepository(
    dataSource: ref.watch(tripRequestRemoteDataSourceProvider),
    failureMapper: ref.watch(apiFailureMapperProvider),
  );
  ref.onDispose(repository.dispose);
  return repository;
});
