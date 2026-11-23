import 'package:teletech_drivers/features/trip_request/domain/repositories/trip_request_repository.dart';

/// Company admin: approve several pending requests with a shared suggestedGroupId.
class ApprovePendingTripRequestsAsGroupUseCase {
  const ApprovePendingTripRequestsAsGroupUseCase(this._repository);

  final TripRequestRepository _repository;

  Future<void> call({
    required List<String> requestIds,
    required String suggestedGroupId,
    required String handledByUid,
    required String handledByName,
  }) {
    return _repository.approvePendingRequestsAsGroup(
      requestIds: requestIds,
      suggestedGroupId: suggestedGroupId.trim(),
      handledByUid: handledByUid,
      handledByName: handledByName.trim(),
    );
  }
}
