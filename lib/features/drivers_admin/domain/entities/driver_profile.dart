import 'package:equatable/equatable.dart';
import 'package:teletech_drivers/features/drivers_admin/domain/entities/driver_private_profile.dart';
import 'package:teletech_drivers/features/drivers_admin/domain/entities/driver_totals.dart';

/// Full driver record for Drivers Admin (public user fields + private profile).
class DriverProfile extends Equatable {
  const DriverProfile({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    required this.email,
    required this.phone,
    required this.isActive,
    required this.privateProfile,
    this.isAvailable = false,
    this.favoritePlaceIds = const [],
    this.totals,
  });

  final String id;
  final String nameEn;
  final String nameAr;
  final String email;
  final String phone;
  final bool isActive;
  final DriverPrivateProfile privateProfile;

  /// Checked in today, not checked out, and not on an active trip.
  final bool isAvailable;

  /// Approved place ids preferred for assignment (Drivers Admin only).
  final List<String> favoritePlaceIds;

  /// Lifetime totals. Present on `GET /drivers/{id}` when the server sends them.
  final DriverTotals? totals;

  /// Picks Arabic or English name for the current UI language.
  String localizedName(String languageCode) {
    if (languageCode == 'ar') {
      final ar = nameAr.trim();
      if (ar.isNotEmpty) return ar;
    }
    final en = nameEn.trim();
    if (en.isNotEmpty) return en;
    return nameAr.trim();
  }

  String get maskedNationalId => privateProfile.maskedNationalId;

  String get nationalId => privateProfile.nationalId;

  String get carLicense => privateProfile.carLicense;

  String get personalLicense => privateProfile.personalLicense;

  @override
  List<Object?> get props => [
    id,
    nameEn,
    nameAr,
    email,
    phone,
    isActive,
    privateProfile,
    isAvailable,
    favoritePlaceIds,
    totals,
  ];
}
