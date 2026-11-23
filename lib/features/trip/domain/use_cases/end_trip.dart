import 'package:teletech_drivers/features/trip/domain/entities/trip_phase_payload.dart';
import 'package:teletech_drivers/features/trip/domain/repositories/trip_repository.dart';

class EndTripUseCase {
  const EndTripUseCase(this._repository);

  final TripRepository _repository;

  Future<void> call({required String tripId, required EndTripPayload payload}) {
    return _repository.endTrip(tripId: tripId, payload: payload);
  }
}
