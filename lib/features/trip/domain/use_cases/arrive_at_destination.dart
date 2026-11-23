import 'package:teletech_drivers/features/trip/domain/entities/trip_phase_payload.dart';
import 'package:teletech_drivers/features/trip/domain/repositories/trip_repository.dart';

class ArriveAtDestinationUseCase {
  const ArriveAtDestinationUseCase(this._repository);

  final TripRepository _repository;

  Future<void> call({
    required String tripId,
    required ArriveDestinationPayload payload,
  }) {
    return _repository.arriveAtDestination(tripId: tripId, payload: payload);
  }
}
