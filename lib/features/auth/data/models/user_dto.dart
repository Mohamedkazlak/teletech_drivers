import 'package:equatable/equatable.dart';
import 'package:teletech_drivers/core/constants/api_json_keys.dart';
import 'package:teletech_drivers/core/network/api_json_parsers.dart';
import 'package:teletech_drivers/features/auth/data/mappers/user_role_mapper.dart';
import 'package:teletech_drivers/features/auth/domain/entities/branch.dart';
import 'package:teletech_drivers/features/auth/domain/entities/user_role.dart';

/// API user JSON (`UserResource` / auth envelope `user`).
final class UserDto extends Equatable {
  const UserDto({
    required this.id,
    required this.email,
    required this.role,
    required this.isActive,
    this.nameEn,
    this.nameAr,
    this.phone,
    this.branch,
    this.isAvailable = false,
    this.favoritePlaceIds = const [],
    this.deletedAt,
    this.deletedBy,
    this.nationalId,
    this.carLicense,
    this.personalLicense,
    this.mustChangePassword = false,
    this.lifetimeTrips,
    this.lifetimeSeconds,
    this.lifetimeKm,
  });

  final String id;
  final String? nameEn;
  final String? nameAr;
  final String email;
  final UserRole role;
  final bool isActive;
  final String? phone;
  final Branch? branch;
  final bool isAvailable;
  final List<String> favoritePlaceIds;
  final DateTime? deletedAt;
  final String? deletedBy;

  final String? nationalId;
  final String? carLicense;
  final String? personalLicense;
  final bool mustChangePassword;

  /// Lifetime totals from `GET /drivers/{id}`. Null on list rows.
  final int? lifetimeTrips;
  final int? lifetimeSeconds;
  final double? lifetimeKm;

  factory UserDto.fromJson(Map<String, dynamic> json) {
    final id = json[ApiJsonKeys.id];
    final email = json[ApiJsonKeys.email];
    final roleRaw = json[ApiJsonKeys.role];
    if (id is! String || id.isEmpty) {
      throw const FormatException('Invalid user id');
    }
    if (email is! String || email.trim().isEmpty) {
      throw const FormatException('Invalid user email');
    }
    if (roleRaw is! String) {
      throw const FormatException('Invalid user role');
    }

    final isActiveValue = json[ApiJsonKeys.isActive];
    final isActive = isActiveValue is bool ? isActiveValue : true;

    return UserDto(
      id: id,
      nameEn: _optionalString(json[ApiJsonKeys.nameEn]),
      nameAr: _optionalString(json[ApiJsonKeys.nameAr]),
      email: email.trim(),
      role: UserRoleMapper.fromApi(roleRaw),
      isActive: isActive,
      phone: _optionalString(json[ApiJsonKeys.phone]),
      branch: _readBranch(json[ApiJsonKeys.branch]),
      isAvailable: ApiJsonParsers.readBool(json[ApiJsonKeys.isAvailable]),
      favoritePlaceIds: _readStringList(json[ApiJsonKeys.favoritePlaceIds]),
      deletedAt: _readDateTime(json[ApiJsonKeys.deletedAt]),
      deletedBy: _optionalString(json[ApiJsonKeys.deletedBy]),
      nationalId: _optionalString(json[ApiJsonKeys.nationalId]),
      carLicense: _optionalString(json[ApiJsonKeys.carLicense]),
      personalLicense: _optionalString(json[ApiJsonKeys.personalLicense]),
      mustChangePassword: ApiJsonParsers.readBool(
        json[ApiJsonKeys.mustChangePassword],
      ),
      lifetimeTrips: _totalsInt(json, ApiJsonKeys.trips),
      lifetimeSeconds: _totalsInt(json, ApiJsonKeys.totalSeconds),
      lifetimeKm: _totalsDouble(json, ApiJsonKeys.totalKm),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      ApiJsonKeys.id: id,
      ApiJsonKeys.nameEn: nameEn,
      ApiJsonKeys.nameAr: nameAr,
      ApiJsonKeys.email: email,
      ApiJsonKeys.role: UserRoleMapper.toApi(role),
      ApiJsonKeys.isActive: isActive,
      ApiJsonKeys.phone: phone,
      ApiJsonKeys.branch: branch?.wireValue,
      ApiJsonKeys.mustChangePassword: mustChangePassword,
      ApiJsonKeys.isAvailable: isAvailable,
      ApiJsonKeys.favoritePlaceIds: favoritePlaceIds,
      ApiJsonKeys.deletedAt: deletedAt?.toIso8601String(),
      ApiJsonKeys.deletedBy: deletedBy,
      if (nationalId != null) ApiJsonKeys.nationalId: nationalId,
      if (carLicense != null) ApiJsonKeys.carLicense: carLicense,
      if (personalLicense != null) ApiJsonKeys.personalLicense: personalLicense,
    };
  }

  static String? _optionalString(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static Branch? _readBranch(Object? value) {
    return ApiJsonParsers.optionalBranch(value);
  }

  static List<String> _readStringList(Object? value) {
    if (value is! List) return const [];
    return [
      for (final item in value)
        if (item is String && item.trim().isNotEmpty) item.trim(),
    ];
  }

  static Map<String, dynamic>? _totals(Map<String, dynamic> json) {
    final raw = json[ApiJsonKeys.totals];
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  static int? _totalsInt(Map<String, dynamic> json, String key) {
    return ApiJsonParsers.optionalInt(_totals(json)?[key]);
  }

  static double? _totalsDouble(Map<String, dynamic> json, String key) {
    return ApiJsonParsers.optionalDouble(_totals(json)?[key]);
  }

  static DateTime? _readDateTime(Object? value) {
    if (value is DateTime) return value;
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  @override
  List<Object?> get props => [
    id,
    nameEn,
    nameAr,
    email,
    role,
    isActive,
    phone,
    branch,
    isAvailable,
    favoritePlaceIds,
    deletedAt,
    deletedBy,
    nationalId,
    carLicense,
    personalLicense,
    mustChangePassword,
    lifetimeTrips,
    lifetimeSeconds,
    lifetimeKm,
  ];
}
