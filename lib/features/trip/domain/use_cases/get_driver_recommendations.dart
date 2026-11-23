import 'package:teletech_drivers/features/drivers_admin/domain/entities/driver_recommendation.dart';
import 'package:teletech_drivers/features/trip/domain/repositories/trip_repository.dart';

class GetDriverRecommendationsUseCase {
  const GetDriverRecommendationsUseCase(this._repository);

  final TripRepository _repository;

  Future<List<DriverRecommendation>> call(String tripId) {
    return _repository.getDriverRecommendations(tripId);
  }
}
