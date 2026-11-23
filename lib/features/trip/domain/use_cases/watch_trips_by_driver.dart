import 'package:teletech_drivers/features/trip/domain/entities/trip.dart';
import 'package:teletech_drivers/features/trip/domain/repositories/trip_repository.dart';

class WatchTripsByDriverUseCase {
  const WatchTripsByDriverUseCase(this._repository);

  final TripRepository _repository;

  /// Observer: emits trips for [driverId] ordered by scheduled time.
  Stream<List<Trip>> call(String driverId) =>
      _repository.watchTripsByDriver(driverId);
}
