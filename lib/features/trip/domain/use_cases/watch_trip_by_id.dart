import 'package:teletech_drivers/features/trip/domain/entities/trip.dart';
import 'package:teletech_drivers/features/trip/domain/repositories/trip_repository.dart';

/// Observer: live updates for a single trip document.
class WatchTripByIdUseCase {
  const WatchTripByIdUseCase(this._repository);

  final TripRepository _repository;

  Stream<Trip?> call(String tripId) => _repository.watchTripById(tripId);
}
