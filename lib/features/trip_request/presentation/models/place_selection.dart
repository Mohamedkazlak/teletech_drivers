import 'package:teletech_drivers/features/place/domain/entities/place.dart';

/// Value object: approved place or employee-entered custom place.
sealed class PlaceSelection {
  const PlaceSelection();

  /// Place id stored on the request (approved id or a stable `custom:` key).
  String get storagePlaceId;

  /// Name snapshot stored on the trip request.
  String storagePlaceName(String languageCode);

  /// Optional map coordinates attached to the trip (custom / map picks).
  double? get lat => null;
  double? get lng => null;
  String? get address => null;

  bool get hasCoordinates => lat != null && lng != null;

  /// Whether pickup and destination refer to the same place.
  static bool isSame(PlaceSelection? a, PlaceSelection? b) {
    if (a == null || b == null) return false;

    if (a is ApprovedPlaceSelection && b is ApprovedPlaceSelection) {
      return a.place.id == b.place.id;
    }

    if (a is CustomPlaceSelection && b is CustomPlaceSelection) {
      if (a.hasCoordinates && b.hasCoordinates) {
        return a.lat == b.lat &&
            a.lng == b.lng &&
            a.trimmedName.toLowerCase() == b.trimmedName.toLowerCase();
      }
      return a.trimmedName.toLowerCase() == b.trimmedName.toLowerCase();
    }

    return a.storagePlaceId == b.storagePlaceId;
  }
}

/// Employee picked an approved [Place].
final class ApprovedPlaceSelection extends PlaceSelection {
  const ApprovedPlaceSelection(this.place);

  final Place place;

  @override
  String get storagePlaceId => place.id;

  @override
  String storagePlaceName(String languageCode) =>
      place.displayName(languageCode);

  @override
  double? get lat => place.latitude;

  @override
  double? get lng => place.longitude;

  @override
  String? get address => place.address;

  @override
  bool operator ==(Object other) =>
      other is ApprovedPlaceSelection && other.place.id == place.id;

  @override
  int get hashCode => place.id.hashCode;
}

/// Employee entered a place that is not in the approved list (text and/or map).
final class CustomPlaceSelection extends PlaceSelection {
  const CustomPlaceSelection([
    this.name = '',
    this.lat,
    this.lng,
    this.address,
  ]);

  /// Max length for a custom place name.
  static const maxNameLength = 100;

  static const _customIdPrefix = 'custom:';

  final String name;

  @override
  final double? lat;

  @override
  final double? lng;

  @override
  final String? address;

  String get trimmedName => name.trim();

  bool get hasName => trimmedName.isNotEmpty;

  /// True when this custom pick came from the map picker.
  bool get isMapPick => hasCoordinates;

  CustomPlaceSelection withName(String value) => CustomPlaceSelection(
    value,
    lat,
    lng,
    address,
  );

  @override
  String get storagePlaceId {
    if (hasCoordinates) {
      final latKey = lat!.toStringAsFixed(5);
      final lngKey = lng!.toStringAsFixed(5);
      return '$_customIdPrefix$latKey,$lngKey';
    }
    final normalized = trimmedName.toLowerCase();
    final key = normalized.length <= maxNameLength
        ? normalized
        : normalized.substring(0, maxNameLength);
    return '$_customIdPrefix$key';
  }

  @override
  String storagePlaceName(String languageCode) => trimmedName;

  /// Menu equality ignores the typed name so the "Other" entry stays selected.
  @override
  bool operator ==(Object other) => other is CustomPlaceSelection;

  @override
  int get hashCode => runtimeType.hashCode;
}
