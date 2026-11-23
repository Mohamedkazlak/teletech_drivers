import 'package:teletech_drivers/features/tracking/domain/repositories/location_repository.dart';

class ClearTrackingUseCase {
  const ClearTrackingUseCase(this._repository);

  final LocationRepository _repository;

  Future<void> call() {
    return _repository.stopTracking();
  }
}
