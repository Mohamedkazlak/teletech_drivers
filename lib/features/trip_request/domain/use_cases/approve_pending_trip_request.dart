import 'package:teletech_drivers/features/trip_request/domain/repositories/trip_request_repository.dart';

class ApprovePendingTripRequestUseCase {
  const ApprovePendingTripRequestUseCase(this._repository);

  final TripRequestRepository _repository;

  Future<void> call({
    required String requestId,
    required String handledByUid,
    required String handledByName,
  }) {
    return _repository.approvePendingRequest(
      requestId: requestId,
      handledByUid: handledByUid,
      handledByName: handledByName.trim(),
    );
  }
}
