import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request.dart';
import 'package:teletech_drivers/features/trip_request/domain/repositories/trip_request_repository.dart';

class WatchEmployeeTripRequestsUseCase {
  const WatchEmployeeTripRequestsUseCase(this._repository);

  final TripRequestRepository _repository;

  /// Observer: emits the employee's requests ordered by newest first.
  Stream<List<TripRequest>> call(String employeeId) {
    return _repository.watchEmployeeRequests(employeeId);
  }
}
