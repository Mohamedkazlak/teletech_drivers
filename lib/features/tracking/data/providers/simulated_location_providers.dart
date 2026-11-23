import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/features/tracking/data/services/simulated_location_source.dart';

/// Debug-only switch that lets trip simulation publish a mocked GPS fix.
final availabilityAllowSimulatedLocationProvider =
    NotifierProvider<AvailabilityAllowSimulatedLocation, bool>(
      AvailabilityAllowSimulatedLocation.new,
    );

class AvailabilityAllowSimulatedLocation extends Notifier<bool> {
  @override
  bool build() => false;

  void setEnabled(bool enabled) {
    assert(!kReleaseMode, 'Simulated location is debug-only');
    if (kReleaseMode) {
      state = false;
      return;
    }
    state = enabled;
  }
}

/// Active debug route simulator. Cleared when simulation stops.
final availabilitySimulatedLocationSourceProvider =
    NotifierProvider<
      AvailabilitySimulatedLocationSourceHolder,
      SimulatedLocationSource?
    >(AvailabilitySimulatedLocationSourceHolder.new);

class AvailabilitySimulatedLocationSourceHolder
    extends Notifier<SimulatedLocationSource?> {
  @override
  SimulatedLocationSource? build() => null;

  void attach(SimulatedLocationSource source) {
    assert(!kReleaseMode, 'SimulatedLocationSource is debug-only');
    if (kReleaseMode) {
      state = null;
      return;
    }
    state = source;
  }

  void clear() {
    state = null;
  }
}
