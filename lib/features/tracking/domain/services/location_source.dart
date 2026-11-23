import 'package:geolocator/geolocator.dart';

/// Strategy: abstraction over real GPS vs debug simulation.
abstract interface class LocationSource {
  /// Last fix this source actually observed. Survives a failed fresh read.
  Position? get cachedPosition;

  /// Continuous position updates for publishing and UI.
  ///
  /// Implementations must share one platform subscription across listeners.
  /// Android exposes a single Geolocator event channel, so a second
  /// position stream cancels the first.
  Stream<Position> watchPositions({required int distanceFilterMeters});

  Future<Position?> getLastKnownPosition();

  /// Fresh fix, or null when GPS fails. Callers keep [cachedPosition].
  Future<Position?> getCurrentPosition({
    required Duration timeout,
  });

  Future<void> dispose();
}
