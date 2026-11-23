import 'package:geolocator/geolocator.dart';
import 'package:teletech_drivers/features/tracking/domain/entities/driver_location_publish_outcome.dart';
import 'package:teletech_drivers/features/tracking/domain/entities/live_map_driver.dart';

/// Repository: driver live location publish/stop and the admin live map.
abstract interface class LocationRepository {
  /// Upserts the signed-in driver's location.
  ///
  /// [tripId] is sent only when non-null (an in-progress trip).
  /// Accuracy failures return [DriverLocationPublishOutcome.skipped].
  /// Throttling returns [DriverLocationPublishOutcome.backedOff].
  Future<DriverLocationPublishOutcome> publishLocation({
    required Position position,
    String? tripId,
  });

  /// Sets tracking off. A missing row (404) is success.
  Future<void> stopTracking();

  /// Observer: live map rows, optionally filtered to one driver.
  Stream<List<LiveMapDriver>> watchLiveMap({String? driverId});
}
