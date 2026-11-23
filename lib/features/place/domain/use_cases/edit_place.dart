import 'package:teletech_drivers/features/place/domain/repositories/place_repository.dart';

class EditPlaceUseCase {
  const EditPlaceUseCase(this._repository);

  final PlaceRepository _repository;

  Future<void> call({
    required String placeId,
    required String nameEn,
    required String nameAr,
    required String address,
    double? latitude,
    double? longitude,
    bool isHeadquarters = false,
  }) {
    return _repository.editPlace(
      placeId: placeId,
      nameEn: nameEn.trim(),
      nameAr: nameAr.trim(),
      address: address.trim(),
      latitude: latitude,
      longitude: longitude,
      isHeadquarters: isHeadquarters,
    );
  }
}
