import 'package:teletech_drivers/features/place/domain/entities/place.dart';

/// Resolves denormalized place labels to the name saved for [languageCode].
class PlaceNameResolver {
  PlaceNameResolver(List<Place> places)
    : _places = List<Place>.unmodifiable(places),
      _placesById = {for (final place in places) place.id: place};

  final List<Place> _places;
  final Map<String, Place> _placesById;

  /// Picks the bilingual place name for [languageCode].
  ///
  /// Prefers [placeId] when present, otherwise matches [storedName] against
  /// either saved language. Falls back to [storedName] for custom/legacy text.
  String resolve({
    required String storedName,
    required String languageCode,
    String? placeId,
  }) {
    final byId = placeId == null ? null : _placesById[placeId];
    if (byId != null) {
      return byId.displayName(languageCode);
    }

    final trimmed = storedName.trim();
    if (trimmed.isEmpty) return storedName;

    for (final place in _places) {
      if (place.nameEn.trim() == trimmed || place.nameAr.trim() == trimmed) {
        return place.displayName(languageCode);
      }
    }
    return storedName;
  }

  /// Localizes a trip summary that may join several place names with ` · `.
  String resolveSummary({
    required String summary,
    required String languageCode,
  }) {
    const separator = ' · ';
    if (!summary.contains(separator)) {
      return resolve(storedName: summary, languageCode: languageCode);
    }
    return summary
        .split(separator)
        .map(
          (part) => resolve(storedName: part, languageCode: languageCode),
        )
        .join(separator);
  }
}
