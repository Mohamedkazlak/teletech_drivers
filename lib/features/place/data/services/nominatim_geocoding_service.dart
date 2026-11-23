import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:teletech_drivers/features/tracking/domain/constants/map_defaults.dart';

/// Search hit from the public Nominatim geocoder (submit-only, no autocomplete).
class NominatimSearchResult {
  const NominatimSearchResult({
    required this.displayName,
    required this.lat,
    required this.lng,
  });

  final String displayName;
  final double lat;
  final double lng;
}

/// Nominatim forward/reverse geocoding (no paid Maps billing).
///
/// Requests send a User-Agent, which Nominatim requires.
class NominatimGeocodingService {
  NominatimGeocodingService({Dio? client}) : _client = client ?? Dio();

  static const _baseUrl = 'https://nominatim.openstreetmap.org';
  static const _userAgent =
      'TeleTechDrivers/1.0 (${MapDefaults.userAgentPackageName})';

  final Dio _client;
  DateTime? _lastRequestAt;

  /// Forward search — call only on explicit submit (Nominatim forbids autocomplete).
  Future<List<NominatimSearchResult>> search(
    String query, {
    int limit = 5,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];

    final uri = Uri.parse('$_baseUrl/search').replace(
      queryParameters: {
        'q': trimmed,
        'format': 'jsonv2',
        'limit': '$limit',
        'addressdetails': '0',
      },
    );

    final json = await _getJson(uri);
    if (json is! List) return const [];

    final results = <NominatimSearchResult>[];
    for (final item in json) {
      if (item is! Map) continue;
      final lat = double.tryParse('${item['lat']}');
      final lng = double.tryParse('${item['lon']}');
      final name = item['display_name'];
      if (lat == null || lng == null || name is! String || name.isEmpty) {
        continue;
      }
      results.add(NominatimSearchResult(displayName: name, lat: lat, lng: lng));
    }
    return results;
  }

  /// Reverse geocode a WGS84 point to a display address.
  Future<String?> reverse({required double lat, required double lng}) async {
    final uri = Uri.parse('$_baseUrl/reverse').replace(
      queryParameters: {
        'lat': lat.toString(),
        'lon': lng.toString(),
        'format': 'jsonv2',
        'zoom': '18',
        'addressdetails': '0',
      },
    );

    final json = await _getJson(uri);
    if (json is! Map) return null;
    final name = json['display_name'];
    if (name is! String || name.trim().isEmpty) return null;
    return name.trim();
  }

  Future<void> _pace() async {
    final last = _lastRequestAt;
    if (last != null) {
      final wait = const Duration(seconds: 1) - DateTime.now().difference(last);
      if (wait > Duration.zero) {
        await Future<void>.delayed(wait);
      }
    }
    _lastRequestAt = DateTime.now();
  }

  Future<Object?> _getJson(Uri uri) async {
    await _pace();
    final response = await _client.getUri<String>(
      uri,
      options: Options(
        responseType: ResponseType.plain,
        receiveTimeout: const Duration(seconds: 12),
        sendTimeout: const Duration(seconds: 12),
        headers: {'user-agent': _userAgent, 'accept': 'application/json'},
      ),
    );
    if (response.statusCode != 200 || response.data == null) {
      throw NominatimException(response.statusCode ?? 0);
    }
    return jsonDecode(response.data!);
  }

  void dispose() {
    _client.close(force: true);
  }
}

class NominatimException implements Exception {
  NominatimException(this.statusCode);

  final int statusCode;

  @override
  String toString() => 'Nominatim HTTP $statusCode';
}
