import 'package:teletech_drivers/features/place/data/models/place_dto.dart';

/// Places REST API.
abstract interface class PlaceRemoteDataSource {
  Future<List<PlaceDto>> listPlaces({bool? isActive});

  Future<PlaceDto> getPlace(String placeId);

  Future<PlaceDto> createPlace(Map<String, dynamic> body);

  Future<PlaceDto> updatePlace({
    required String placeId,
    required Map<String, dynamic> body,
  });

  Future<void> deletePlace(String placeId);
}
