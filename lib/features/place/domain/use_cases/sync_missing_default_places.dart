import 'package:teletech_drivers/features/place/domain/repositories/place_repository.dart';

class SyncMissingDefaultPlacesUseCase {
  const SyncMissingDefaultPlacesUseCase(this._repository);

  final PlaceRepository _repository;

  /// Returns how many places were created.
  Future<int> call() => _repository.syncMissingDefaultPlaces();
}
