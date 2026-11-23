import 'package:equatable/equatable.dart';
import 'package:teletech_drivers/features/auth/domain/entities/branch.dart';
import 'package:teletech_drivers/features/auth/domain/entities/user_role.dart';

/// Signed-in person, including the role used for navigation.
class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.isActive = true,
    this.phone,
    this.branch,
    this.nameEn,
    this.nameAr,
    this.isAvailable = false,
    this.favoritePlaceIds = const [],
    this.deletedAt,
    this.deletedBy,
    this.mustChangePassword = false,
  });

  final String id;

  /// Primary display name (employees/admins; drivers keep English as fallback).
  final String name;

  final String email;
  final UserRole role;

  /// Soft flag. Inactive users cannot sign in and are hidden from dropdowns.
  final bool isActive;

  /// Contact number (required for employees and drivers).
  final String? phone;

  /// Office branch (required for employees; optional for other roles).
  final Branch? branch;

  /// English name for drivers (null on non-driver / legacy profiles).
  final String? nameEn;

  /// Arabic name for drivers (null on non-driver / legacy profiles).
  final String? nameAr;

  /// Checked in today, not checked out, and not on an active trip.
  final bool isAvailable;

  /// Approved place ids preferred for this driver (Drivers Admin only; empty default).
  final List<String> favoritePlaceIds;

  /// Soft-delete timestamp (null when active / never soft-deleted).
  final DateTime? deletedAt;

  /// Auth uid of the admin who soft-deleted this user.
  final String? deletedBy;

  /// Server flag. Other API calls return 403 `password_change_required`.
  final bool mustChangePassword;

  AppUser copyWithMustChangePassword(bool value) {
    if (mustChangePassword == value) return this;
    return AppUser(
      id: id,
      name: name,
      email: email,
      role: role,
      isActive: isActive,
      phone: phone,
      branch: branch,
      nameEn: nameEn,
      nameAr: nameAr,
      isAvailable: isAvailable,
      favoritePlaceIds: favoritePlaceIds,
      deletedAt: deletedAt,
      deletedBy: deletedBy,
      mustChangePassword: value,
    );
  }

  /// Employees and admins who request trips need branch and phone.
  bool get needsProfileCompletion {
    final requiresBranchPhone =
        role == UserRole.employee ||
        role == UserRole.companyAdmin ||
        role == UserRole.driversAdmin ||
        role == UserRole.admin;
    if (!requiresBranchPhone) return false;
    final phoneValue = phone?.trim();
    return branch == null || phoneValue == null || phoneValue.isEmpty;
  }

  /// Name for the current UI language (drivers use EN/AR; others use [name]).
  String localizedName(String languageCode) {
    if (role == UserRole.driver) {
      if (languageCode == 'ar') {
        final ar = nameAr?.trim();
        if (ar != null && ar.isNotEmpty) return ar;
      }
      final en = nameEn?.trim();
      if (en != null && en.isNotEmpty) return en;
      final ar = nameAr?.trim();
      if (ar != null && ar.isNotEmpty) return ar;
    }
    return name;
  }

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    role,
    isActive,
    phone,
    branch,
    nameEn,
    nameAr,
    isAvailable,
    favoritePlaceIds,
    deletedAt,
    deletedBy,
    mustChangePassword,
  ];
}
