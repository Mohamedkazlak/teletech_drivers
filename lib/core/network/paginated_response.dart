import 'package:teletech_drivers/core/constants/api_json_keys.dart';

/// `{ data, meta }` envelope from Laravel list endpoints.
final class PaginatedResponse<T> {
  const PaginatedResponse({
    required this.data,
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  final List<T> data;
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  bool get hasMore => currentPage < lastPage;

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> item) mapItem,
  ) {
    final rawData = json[ApiJsonKeys.data];
    if (rawData is! List) {
      throw const FormatException('Invalid paginated response');
    }
    final items = <T>[];
    for (final entry in rawData) {
      if (entry is! Map) {
        throw const FormatException('Invalid paginated item');
      }
      items.add(mapItem(Map<String, dynamic>.from(entry)));
    }

    final meta = json[ApiJsonKeys.meta];
    if (meta is! Map) {
      throw const FormatException('Invalid paginated meta');
    }
    final metaMap = Map<String, dynamic>.from(meta);

    return PaginatedResponse<T>(
      data: items,
      currentPage: _readPositiveInt(metaMap[ApiJsonKeys.currentPage]),
      lastPage: _readPositiveInt(metaMap[ApiJsonKeys.lastPage]),
      perPage: _readPositiveInt(metaMap[ApiJsonKeys.perPage]),
      total: _readNonNegativeInt(metaMap[ApiJsonKeys.total]),
    );
  }

  static int _readPositiveInt(Object? value) {
    if (value is int && value > 0) return value;
    if (value is num && value.toInt() > 0) return value.toInt();
    throw const FormatException('Invalid pagination page number');
  }

  static int _readNonNegativeInt(Object? value) {
    if (value is int && value >= 0) return value;
    if (value is num && value.toInt() >= 0) return value.toInt();
    throw const FormatException('Invalid pagination total');
  }
}
