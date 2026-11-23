import 'package:geolocator/geolocator.dart';
import 'package:teletech_drivers/core/constants/api_json_keys.dart';
import 'package:teletech_drivers/core/constants/api_paths.dart';
import 'package:teletech_drivers/core/network/api_client.dart';
import 'package:teletech_drivers/core/network/api_exception.dart';
import 'package:teletech_drivers/core/network/api_json_parsers.dart';
import 'package:teletech_drivers/features/tracking/data/datasources/location_remote_data_source.dart';
import 'package:teletech_drivers/features/tracking/data/models/live_map_item_dto.dart';

class ApiLocationRemoteDataSource implements LocationRemoteDataSource {
  const ApiLocationRemoteDataSource({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<void> publish({required Position position, String? tripId}) async {
    final id = tripId?.trim();
    await apiClient.put(
      ApiPaths.driverLocation,
      data: {
        ApiJsonKeys.lat: position.latitude,
        ApiJsonKeys.lng: position.longitude,
        ApiJsonKeys.heading: _finite(position.heading),
        ApiJsonKeys.speed: _nonNegative(position.speed),
        ApiJsonKeys.accuracy: _nonNegative(position.accuracy),
        ApiJsonKeys.isTracking: true,
        if (id != null && id.isNotEmpty) ApiJsonKeys.tripId: id,
      },
    );
  }

  @override
  Future<void> stop() async {
    try {
      await apiClient.post(ApiPaths.driverLocationStop);
    } on NotFoundApiException {
      // No location row yet: tracking is already off.
    }
  }

  @override
  Future<List<LiveMapItemDto>> listLiveMap({String? driverId}) async {
    final id = driverId?.trim();
    final response = await apiClient.get(
      ApiPaths.liveMap,
      queryParameters: {
        if (id != null && id.isNotEmpty) ApiJsonKeys.driverId: id,
      },
    );
    final body = ApiJsonParsers.requireMap(response.data);
    return [
      for (final item in ApiJsonParsers.objectList(
        body[ApiJsonKeys.data],
        ApiJsonKeys.data,
      ))
        LiveMapItemDto.fromJson(item),
    ];
  }

  static double _finite(double value) {
    if (!value.isFinite) return 0;
    return value;
  }

  static double _nonNegative(double value) {
    if (!value.isFinite || value < 0) return 0;
    return value;
  }
}
