import 'package:teletech_drivers/features/trip/domain/entities/trip.dart';
import 'package:teletech_drivers/features/trip/domain/repositories/trip_repository.dart';

class GetTripByIdUseCase {
  const GetTripByIdUseCase(this._repository);

  final TripRepository _repository;

  Future<Trip?> call(String tripId) => _repository.getTripById(tripId);
}
