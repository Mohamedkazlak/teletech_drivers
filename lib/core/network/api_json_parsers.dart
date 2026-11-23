import 'package:teletech_drivers/features/auth/domain/entities/branch.dart';

/// Shared typed JSON readers for API DTOs (no business logic).
abstract final class ApiJsonParsers {
  static Map<String, dynamic> requireMap(Object? data, [String label = 'JSON']) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw FormatException('Expected $label object');
  }

  static String requireNonEmptyString(Object? value, String field) {
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Invalid $field');
    }
    return value.trim();
  }

  static String? optionalString(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static bool readBool(Object? value, {bool fallback = false}) {
    if (value is bool) return value;
    return fallback;
  }

  /// Null when the field is absent. A non-bool value is invalid.
  static bool? optionalBool(Object? value, String field) {
    if (value == null) return null;
    if (value is bool) return value;
    throw FormatException('Invalid $field');
  }

  static double? optionalDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      return double.tryParse(trimmed);
    }
    return null;
  }

  static int? optionalInt(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return null;
  }

  static int requireInt(Object? value, String field) {
    final parsed = optionalInt(value);
    if (parsed == null) {
      throw FormatException('Invalid $field');
    }
    return parsed;
  }

  /// Parses UTC ISO-8601; keeps [DateTime.isUtc] true when the string is UTC.
  static DateTime? optionalDateTime(Object? value) {
    if (value is DateTime) return value.toUtc();
    if (value is! String || value.isEmpty) return null;
    final parsed = DateTime.tryParse(value);
    return parsed?.toUtc();
  }

  static DateTime requireDateTime(Object? value, String field) {
    final parsed = optionalDateTime(value);
    if (parsed == null) {
      throw FormatException('Invalid $field');
    }
    return parsed;
  }

  static Branch? optionalBranch(Object? value) {
    if (value == null) return null;
    if (value is! String) {
      throw const FormatException('Invalid branch');
    }
    return Branch.fromWire(value);
  }

  static List<String> stringList(Object? value) {
    if (value is! List) return const [];
    return [
      for (final item in value)
        if (item is String && item.trim().isNotEmpty) item.trim(),
    ];
  }

  static List<Map<String, dynamic>> objectList(Object? value, String field) {
    if (value == null) return const [];
    if (value is! List) {
      throw FormatException('Invalid $field');
    }
    return [
      for (final item in value) requireMap(item, field),
    ];
  }
}
