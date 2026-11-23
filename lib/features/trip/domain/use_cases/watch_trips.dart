import 'package:teletech_drivers/features/trip/domain/entities/trip.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_list_query.dart';
import 'package:teletech_drivers/features/trip/domain/repositories/trip_repository.dart';

class WatchTripsUseCase {
  const WatchTripsUseCase(this._repository);

  final TripRepository _repository;

  Stream<List<Trip>> call(TripListQuery query) => _repository.watchTrips(query);
}
