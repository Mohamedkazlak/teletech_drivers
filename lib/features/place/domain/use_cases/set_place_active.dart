import 'package:teletech_drivers/features/place/domain/repositories/place_repository.dart';

class SetPlaceActiveUseCase {
  const SetPlaceActiveUseCase(this._repository);

  final PlaceRepository _repository;

  Future<void> call({
    required String placeId,
    required bool isActive,
  }) {
    return _repository.setPlaceActive(
      placeId: placeId,
      isActive: isActive,
    );
  }
}
