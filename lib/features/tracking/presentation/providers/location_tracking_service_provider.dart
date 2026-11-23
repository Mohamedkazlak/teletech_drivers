import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/features/tracking/data/services/geolocator_location_tracking_service.dart';
import 'package:teletech_drivers/features/tracking/data/services/real_location_source.dart';
import 'package:teletech_drivers/features/tracking/domain/services/location_source.dart';
import 'package:teletech_drivers/features/tracking/domain/services/location_tracking_service.dart';

/// Dependency Injection: Riverpod. One GPS subscription for the whole app.
final locationSourceProvider = Provider<LocationSource>((ref) {
  final source = RealLocationSource();
  ref.onDispose(() {
    unawaited(source.dispose());
  });
  return source;
});

/// Dependency Injection: Riverpod. Singleton GPS phase tracker.
final locationTrackingServiceProvider = Provider<LocationTrackingService>((
  ref,
) {
  final service = GeolocatorLocationTrackingService(
    locationSource: ref.watch(locationSourceProvider),
  );
  ref.onDispose(() {
    unawaited(service.dispose());
  });
  return service;
});
