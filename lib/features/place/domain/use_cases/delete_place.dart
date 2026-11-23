import 'package:teletech_drivers/features/place/domain/repositories/place_repository.dart';

class DeletePlaceUseCase {
  const DeletePlaceUseCase(this._repository);

  final PlaceRepository _repository;

  Future<void> call(String placeId) => _repository.deletePlace(placeId);
}
