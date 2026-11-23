import 'package:teletech_drivers/features/place/domain/entities/place.dart';
import 'package:teletech_drivers/features/place/domain/repositories/place_repository.dart';

class WatchAllPlacesUseCase {
  const WatchAllPlacesUseCase(this._repository);

  final PlaceRepository _repository;

  /// Observer: all places for company admin, sorted by name.
  Stream<List<Place>> call() => _repository.watchAllPlaces();
}
