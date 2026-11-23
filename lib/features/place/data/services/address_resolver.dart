import 'package:geocoding/geocoding.dart';
import 'package:teletech_drivers/features/place/data/services/nominatim_geocoding_service.dart';

/// Resolves a map center to a human-readable address.
///
/// Strategy: platform [Geocoding] first, then Nominatim reverse as fallback.
class AddressResolver {
  AddressResolver({NominatimGeocodingService? nominatim, Geocoding? geocoding})
    : _nominatim = nominatim ?? NominatimGeocodingService(),
      _ownsNominatim = nominatim == null,
      _geocoding = geocoding ?? Geocoding();

  final NominatimGeocodingService _nominatim;
  final bool _ownsNominatim;
  final Geocoding _geocoding;

  Future<String?> resolve({required double lat, required double lng}) async {
    final fromPlatform = await _fromPlatform(lat: lat, lng: lng);
    if (fromPlatform != null) return fromPlatform;
    try {
      return await _nominatim.reverse(lat: lat, lng: lng);
    } on Object {
      return null;
    }
  }

  Future<String?> _fromPlatform({
    required double lat,
    required double lng,
  }) async {
    try {
      final places = await _geocoding.placemarkFromCoordinates(lat, lng);
      if (places.isEmpty) return null;
      return _formatPlacemark(places.first);
    } on Object {
      return null;
    }
  }

  String? _formatPlacemark(Placemark place) {
    final parts = <String>[
      if ((place.name ?? '').trim().isNotEmpty) place.name!.trim(),
      if ((place.street ?? '').trim().isNotEmpty &&
          place.street!.trim() != place.name?.trim())
        place.street!.trim(),
      if ((place.subLocality ?? '').trim().isNotEmpty)
        place.subLocality!.trim(),
      if ((place.locality ?? '').trim().isNotEmpty) place.locality!.trim(),
      if ((place.administrativeArea ?? '').trim().isNotEmpty)
        place.administrativeArea!.trim(),
      if ((place.country ?? '').trim().isNotEmpty) place.country!.trim(),
    ];
    if (parts.isEmpty) return null;
    return parts.join(', ');
  }

  void dispose() {
    if (_ownsNominatim) _nominatim.dispose();
  }
}
