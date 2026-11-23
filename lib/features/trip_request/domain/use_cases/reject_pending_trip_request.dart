import 'package:teletech_drivers/features/trip_request/domain/repositories/trip_request_repository.dart';

class RejectPendingTripRequestUseCase {
  const RejectPendingTripRequestUseCase(this._repository);

  final TripRequestRepository _repository;

  Future<void> call({
    required String requestId,
    required String handledByUid,
    required String handledByName,
    String? reason,
  }) {
    final trimmed = reason?.trim();
    return _repository.rejectPendingRequest(
      requestId: requestId,
      handledByUid: handledByUid,
      handledByName: handledByName.trim(),
      reason: (trimmed == null || trimmed.isEmpty) ? null : trimmed,
    );
  }
}
