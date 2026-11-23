import 'package:teletech_drivers/features/trip/domain/entities/mine_trips_filter.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip.dart';
import 'package:teletech_drivers/features/trip/domain/repositories/trip_repository.dart';

/// Observer: the signed-in driver's trips for one status and fleet period.
class WatchMyTripsUseCase {
  const WatchMyTripsUseCase(this._repository);

  final TripRepository _repository;

  Stream<List<Trip>> call(MineTripsFilter filter) {
    return _repository.watchMyTrips(filter);
  }
}
