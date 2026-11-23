import 'package:teletech_drivers/features/trip/domain/repositories/trip_repository.dart';

class AssignDriverUseCase {
  const AssignDriverUseCase(this._repository);

  final TripRepository _repository;

  Future<void> call({required String tripId, required String driverId}) {
    return _repository.assignDriver(tripId: tripId, driverId: driverId);
  }
}
