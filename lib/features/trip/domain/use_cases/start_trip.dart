import 'package:teletech_drivers/features/trip/domain/entities/trip_phase_payload.dart';
import 'package:teletech_drivers/features/trip/domain/repositories/trip_repository.dart';

class StartTripUseCase {
  const StartTripUseCase(this._repository);

  final TripRepository _repository;

  Future<void> call({
    required String tripId,
    required StartTripPayload payload,
  }) {
    return _repository.startTrip(tripId: tripId, payload: payload);
  }
}
