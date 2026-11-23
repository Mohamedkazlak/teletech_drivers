import 'package:teletech_drivers/features/place/domain/entities/place.dart';
import 'package:teletech_drivers/features/place/domain/repositories/place_repository.dart';

class WatchActivePlacesUseCase {
  const WatchActivePlacesUseCase(this._repository);

  final PlaceRepository _repository;

  /// Observer: active places sorted by name.
  Stream<List<Place>> call() => _repository.watchActivePlaces();
}
