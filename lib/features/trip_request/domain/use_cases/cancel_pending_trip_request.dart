import 'package:teletech_drivers/features/trip_request/domain/repositories/trip_request_repository.dart';

class CancelPendingTripRequestUseCase {
  const CancelPendingTripRequestUseCase(this._repository);

  final TripRequestRepository _repository;

  Future<void> call({
    required String requestId,
    required String employeeId,
  }) {
    return _repository.cancelPendingRequest(
      requestId: requestId,
      employeeId: employeeId,
    );
  }
}
