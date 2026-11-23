import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request.dart';
import 'package:teletech_drivers/features/trip_request/domain/repositories/trip_request_repository.dart';

/// Observer: live updates for one trip request document.
class WatchTripRequestByIdUseCase {
  const WatchTripRequestByIdUseCase(this._repository);

  final TripRequestRepository _repository;

  Stream<TripRequest?> call(String requestId) {
    if (requestId.isEmpty) {
      return Stream<TripRequest?>.value(null);
    }
    return _repository.watchRequestById(requestId);
  }
}
