import 'package:teletech_drivers/features/place/domain/repositories/place_repository.dart';

class SeedDefaultPlacesUseCase {
  const SeedDefaultPlacesUseCase(this._repository);

  final PlaceRepository _repository;

  /// One-time seed of sample places when the list is empty.
  Future<void> call() => _repository.seedDefaultPlaces();
}
