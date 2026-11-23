import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request.dart';
import 'package:teletech_drivers/features/trip_request/domain/repositories/trip_request_repository.dart';

class WatchPendingTripRequestsUseCase {
  const WatchPendingTripRequestsUseCase(this._repository);

  final TripRequestRepository _repository;

  /// Observer: pending requests ordered by earliest requested time.
  Stream<List<TripRequest>> call() => _repository.watchPendingRequests();
}
