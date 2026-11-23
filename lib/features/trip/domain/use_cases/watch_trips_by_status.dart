import 'package:teletech_drivers/features/trip/domain/entities/trip.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_status.dart';
import 'package:teletech_drivers/features/trip/domain/repositories/trip_repository.dart';

class WatchTripsByStatusUseCase {
  const WatchTripsByStatusUseCase(this._repository);

  final TripRepository _repository;

  /// Observer: emits trips with [status], newest first.
  Stream<List<Trip>> call(TripStatus status) {
    return _repository.watchTripsByStatus(status);
  }
}
