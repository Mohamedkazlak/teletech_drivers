import 'package:equatable/equatable.dart';

/// An approved pickup/destination place managed by company admin.
class Place extends Equatable {
  const Place({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.isActive,
    this.createdAt,
    this.latitude,
    this.longitude,
    this.address,
    this.isHeadquarters = false,
  });

  final String id;
  final String nameEn;
  final String nameAr;
  final bool isActive;

  /// Server `created_at` (UTC), or null when the API omits it.
  final DateTime? createdAt;

  /// Optional WGS84 latitude (null on legacy docs without coordinates).
  final double? latitude;

  /// Optional WGS84 longitude (null on legacy docs without coordinates).
  final double? longitude;

  /// Optional human-readable address (null on legacy docs).
  final String? address;

  /// Company HQ flag — at most one place should be true at a time.
  final bool isHeadquarters;

  /// True only when both coordinates are present and finite.
  bool get hasCoordinates =>
      latitude != null &&
      longitude != null &&
      latitude!.isFinite &&
      longitude!.isFinite;

  /// Localized display name with fallback to the other language.
  String displayName(String languageCode) {
    if (languageCode == 'ar') {
      final ar = nameAr.trim();
      if (ar.isNotEmpty) return ar;
      return nameEn.trim();
    }
    final en = nameEn.trim();
    if (en.isNotEmpty) return en;
    return nameAr.trim();
  }

  @override
  List<Object?> get props => [
    id,
    nameEn,
    nameAr,
    isActive,
    createdAt,
    latitude,
    longitude,
    address,
    isHeadquarters,
  ];
}
