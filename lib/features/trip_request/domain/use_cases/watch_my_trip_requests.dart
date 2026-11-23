import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request_list_bucket.dart';
import 'package:teletech_drivers/features/trip_request/domain/repositories/trip_request_repository.dart';

/// Observer: the signed-in user's requests, optionally one list bucket.
class WatchMyTripRequestsUseCase {
  const WatchMyTripRequestsUseCase(this._repository);

  final TripRequestRepository _repository;

  Stream<List<TripRequest>> call(TripRequestListBucket? bucket) {
    return _repository.watchMyRequests(bucket: bucket);
  }
}
