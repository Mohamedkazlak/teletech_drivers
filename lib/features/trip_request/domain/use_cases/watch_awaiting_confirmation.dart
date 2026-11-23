import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request.dart';
import 'package:teletech_drivers/features/trip_request/domain/repositories/trip_request_repository.dart';

/// Observer: requests whose completed trip still needs a report.
class WatchAwaitingConfirmationUseCase {
  const WatchAwaitingConfirmationUseCase(this._repository);

  final TripRequestRepository _repository;

  Stream<List<TripRequest>> call() {
    return _repository.watchAwaitingConfirmation();
  }
}
