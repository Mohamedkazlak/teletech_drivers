import 'package:teletech_drivers/features/tracking/domain/entities/tracked_location_point.dart';
import 'package:teletech_drivers/features/tracking/domain/services/geo_math.dart';

/// Filters raw GPS samples before they enter the trip track.
class LocationPointFilter {
  const LocationPointFilter({
    this.maxAccuracyMeters = 30,
    this.minDistanceMeters = 5,
    this.maxSpeedMps = 55,
  });

  final double maxAccuracyMeters;
  final double minDistanceMeters;
  final double maxSpeedMps;

  /// Returns true when [candidate] should be kept after [lastAccepted].
  bool shouldAccept(
    TrackedLocationPoint candidate, {
    TrackedLocationPoint? lastAccepted,
  }) {
    if (candidate.accuracyMeters > maxAccuracyMeters) return false;
    if (lastAccepted == null) return true;

    final distance = GeoMath.distanceMeters(
      lastAccepted.asRoutePoint,
      candidate.asRoutePoint,
    );
    if (distance < minDistanceMeters) return false;

    final elapsedSeconds =
        candidate.timestamp.difference(lastAccepted.timestamp).inMilliseconds /
        1000.0;
    if (elapsedSeconds > 0) {
      final impliedSpeed = distance / elapsedSeconds;
      if (impliedSpeed > maxSpeedMps) return false;
    }

    return true;
  }
}
