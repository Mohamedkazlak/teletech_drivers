import 'package:teletech_drivers/features/trip/domain/entities/trip.dart';
import 'package:teletech_drivers/features/trip/domain/repositories/trip_repository.dart';

class WatchAllTripsUseCase {
  const WatchAllTripsUseCase(this._repository);

  final TripRepository _repository;

  /// Observer: emits all trips ordered by newest first.
  Stream<List<Trip>> call() => _repository.watchAllTrips();
}
