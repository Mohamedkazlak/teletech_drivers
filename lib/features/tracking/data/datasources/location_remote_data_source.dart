import 'package:geolocator/geolocator.dart';
import 'package:teletech_drivers/features/tracking/data/models/live_map_item_dto.dart';

/// Remote driver-location and live-map API.
abstract interface class LocationRemoteDataSource {
  Future<void> publish({
    required Position position,
    String? tripId,
  });

  /// 404 (no row yet) completes successfully.
  Future<void> stop();

  Future<List<LiveMapItemDto>> listLiveMap({String? driverId});
}
