import 'package:teletech_drivers/features/place/domain/entities/place.dart';

/// Repository: approved places.
abstract interface class PlaceRepository {
  /// Observer: active places sorted by English name.
  Stream<List<Place>> watchActivePlaces();

  /// Observer: all places for company admin, sorted by English name.
  Stream<List<Place>> watchAllPlaces();

  /// Creates a new active place. Coordinates are optional and must be a pair.
  ///
  /// When [isHeadquarters] is true, clears the flag on every other place.
  Future<void> addPlace({
    required String nameEn,
    required String nameAr,
    required String address,
    double? latitude,
    double? longitude,
    bool isHeadquarters = false,
  });

  /// Updates place names, address, and coordinates. Does not change [Place.isActive].
  ///
  /// When [isHeadquarters] is true, clears the flag on every other place.
  Future<void> editPlace({
    required String placeId,
    required String nameEn,
    required String nameAr,
    required String address,
    double? latitude,
    double? longitude,
    bool isHeadquarters = false,
  });

  /// Soft-activates or deactivates a place.
  Future<void> setPlaceActive({
    required String placeId,
    required bool isActive,
  });

  /// Permanently removes a place.
  Future<void> deletePlace(String placeId);

  /// Creates the default company places when the collection is empty.
  Future<void> seedDefaultPlaces();

  /// Creates any default places that are not already present.
  ///
  /// Returns how many places were created.
  Future<int> syncMissingDefaultPlaces();

  /// Returns the place flagged as headquarters, or null when none is set.
  Future<Place?> findHeadquarters();
}
