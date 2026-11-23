import 'package:teletech_drivers/features/place/domain/entities/place.dart';

/// Resolves display coordinates from a request snapshot or approved place.
abstract final class PlaceCoordinateLookup {
  /// Prefer request-level coordinates, then the approved [Place] by id.
  static ({double? latitude, double? longitude}) resolve({
    required double? requestLatitude,
    required double? requestLongitude,
    required String? placeId,
    required List<Place> places,
  }) {
    if (requestLatitude != null && requestLongitude != null) {
      return (latitude: requestLatitude, longitude: requestLongitude);
    }
    if (placeId == null || placeId.isEmpty) {
      return (latitude: null, longitude: null);
    }
    for (final place in places) {
      if (place.id != placeId) continue;
      if (!place.hasCoordinates) {
        return (latitude: null, longitude: null);
      }
      return (latitude: place.latitude, longitude: place.longitude);
    }
    return (latitude: null, longitude: null);
  }
}
