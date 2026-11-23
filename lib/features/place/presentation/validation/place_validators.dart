import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/features/place/domain/entities/place.dart';

/// Form validators for creating or editing a place.
abstract final class PlaceValidators {
  static String? nameEn(
    String? value,
    AppLocalizations l10n, {
    required List<Place> existingPlaces,
    String? excludingPlaceId,
  }) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return l10n.validationPlaceNameEnRequired;
    }
    if (_hasDuplicateEn(
      trimmed,
      existingPlaces,
      excludingPlaceId: excludingPlaceId,
    )) {
      return l10n.validationPlaceNameDuplicate;
    }
    return null;
  }

  static String? nameAr(
    String? value,
    AppLocalizations l10n, {
    required List<Place> existingPlaces,
    String? excludingPlaceId,
  }) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return l10n.validationPlaceNameArRequired;
    }
    if (_hasDuplicateAr(
      trimmed,
      existingPlaces,
      excludingPlaceId: excludingPlaceId,
    )) {
      return l10n.validationPlaceNameDuplicate;
    }
    return null;
  }

  static String? address(String? value, AppLocalizations l10n) {
    if (value == null || value.trim().isEmpty) {
      return l10n.validationPlaceAddressRequired;
    }
    return null;
  }

  /// Both coordinates may be empty. One without the other, or a value
  /// outside WGS84, is invalid.
  static String? coordinates(
    double? latitude,
    double? longitude,
    AppLocalizations l10n,
  ) {
    if (latitude == null && longitude == null) return null;
    if (latitude == null || longitude == null) {
      return l10n.validationPlaceCoordinatePair;
    }
    if (latitude < -90 || latitude > 90) {
      return l10n.validationLatitudeInvalid;
    }
    if (longitude < -180 || longitude > 180) {
      return l10n.validationLongitudeInvalid;
    }
    return null;
  }

  static bool isValidLatitude(double value) => value >= -90 && value <= 90;

  static bool isValidLongitude(double value) => value >= -180 && value <= 180;

  static bool _hasDuplicateEn(
    String nameEn,
    List<Place> existingPlaces, {
    String? excludingPlaceId,
  }) {
    final key = nameEn.toLowerCase();
    return existingPlaces.any(
      (place) =>
          place.id != excludingPlaceId && place.nameEn.toLowerCase() == key,
    );
  }

  static bool _hasDuplicateAr(
    String nameAr,
    List<Place> existingPlaces, {
    String? excludingPlaceId,
  }) {
    final key = nameAr.toLowerCase();
    return existingPlaces.any(
      (place) =>
          place.id != excludingPlaceId && place.nameAr.toLowerCase() == key,
    );
  }
}
