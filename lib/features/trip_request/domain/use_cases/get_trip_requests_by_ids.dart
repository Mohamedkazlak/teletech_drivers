import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request.dart';
import 'package:teletech_drivers/features/trip_request/domain/repositories/trip_request_repository.dart';

class GetTripRequestsByIdsUseCase {
  const GetTripRequestsByIdsUseCase(this._repository);

  final TripRequestRepository _repository;

  Future<List<TripRequest>> call(List<String> requestIds) {
    return _repository.getRequestsByIds(requestIds);
  }
}
