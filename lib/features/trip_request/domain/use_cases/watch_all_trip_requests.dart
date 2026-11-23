import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request.dart';
import 'package:teletech_drivers/features/trip_request/domain/repositories/trip_request_repository.dart';

class WatchAllTripRequestsUseCase {
  const WatchAllTripRequestsUseCase(this._repository);

  final TripRequestRepository _repository;

  Stream<List<TripRequest>> call() => _repository.watchAllRequests();
}
