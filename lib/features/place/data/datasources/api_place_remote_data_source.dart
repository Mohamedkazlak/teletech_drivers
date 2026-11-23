import 'package:teletech_drivers/core/constants/api_json_keys.dart';
import 'package:teletech_drivers/core/constants/api_paths.dart';
import 'package:teletech_drivers/core/network/api_client.dart';
import 'package:teletech_drivers/features/place/data/datasources/place_remote_data_source.dart';
import 'package:teletech_drivers/features/place/data/models/place_dto.dart';

class ApiPlaceRemoteDataSource implements PlaceRemoteDataSource {
  const ApiPlaceRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  /// Laravel `boolean` query rules accept `1`/`0`, not the strings `"true"` / `"false"`.
  static int? _boolQuery(bool? value) {
    if (value == null) return null;
    return value ? 1 : 0;
  }

  @override
  Future<List<PlaceDto>> listPlaces({bool? isActive}) {
    return apiClient.fetchAllPages(
      path: ApiPaths.places,
      query: {ApiJsonKeys.isActive: ?_boolQuery(isActive)},
      mapItem: PlaceDto.fromJson,
    );
  }

  @override
  Future<PlaceDto> getPlace(String placeId) async {
    final response = await apiClient.get(ApiPaths.place(placeId));
    return PlaceDto.fromJson(_asMap(response.data));
  }

  @override
  Future<PlaceDto> createPlace(Map<String, dynamic> body) async {
    final response = await apiClient.post(ApiPaths.places, data: body);
    return PlaceDto.fromJson(_asMap(response.data));
  }

  @override
  Future<PlaceDto> updatePlace({
    required String placeId,
    required Map<String, dynamic> body,
  }) async {
    final response = await apiClient.patch(ApiPaths.place(placeId), data: body);
    return PlaceDto.fromJson(_asMap(response.data));
  }

  @override
  Future<void> deletePlace(String placeId) async {
    await apiClient.delete(ApiPaths.place(placeId));
  }

  static Map<String, dynamic> _asMap(Object? data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const FormatException('Expected JSON object');
  }
}
