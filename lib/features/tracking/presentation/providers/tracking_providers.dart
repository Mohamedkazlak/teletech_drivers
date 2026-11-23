import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:teletech_drivers/features/auth/presentation/providers/auth_bound_stream.dart';
import 'package:teletech_drivers/features/place/domain/entities/place.dart';
import 'package:teletech_drivers/features/place/presentation/providers/place_providers.dart';
import 'package:teletech_drivers/features/tracking/data/providers/location_repository_provider.dart';
import 'package:teletech_drivers/features/tracking/data/services/osrm_routing_service.dart';
import 'package:teletech_drivers/features/tracking/domain/entities/live_map_driver.dart';
import 'package:teletech_drivers/features/tracking/domain/services/routing_service.dart';
import 'package:teletech_drivers/features/tracking/domain/use_cases/clear_tracking.dart';
import 'package:teletech_drivers/features/tracking/domain/use_cases/publish_location.dart';
import 'package:teletech_drivers/features/tracking/domain/use_cases/watch_live_map.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request.dart';
import 'package:teletech_drivers/features/trip_request/presentation/providers/trip_request_providers.dart';

final publishLocationUseCaseProvider = Provider<PublishLocationUseCase>((ref) {
  return PublishLocationUseCase(ref.watch(locationRepositoryProvider));
});

final clearTrackingUseCaseProvider = Provider<ClearTrackingUseCase>((ref) {
  return ClearTrackingUseCase(ref.watch(locationRepositoryProvider));
});

final watchLiveMapUseCaseProvider = Provider<WatchLiveMapUseCase>((ref) {
  return WatchLiveMapUseCase(ref.watch(locationRepositoryProvider));
});

/// Drivers Admin live map. Polled every 20s while the screen is open.
///
/// [driverId] is the optional `GET /live-map?driver_id=` filter.
final adminLiveMapLocationsProvider = StreamProvider.autoDispose
    .family<List<LiveMapDriver>, String?>((ref, driverId) {
      return authBoundStream(
        ref,
        whenSignedOut: const <LiveMapDriver>[],
        create: (_) => ref.watch(watchLiveMapUseCaseProvider)(driverId),
      );
    }, retry: (_, _) => null);

/// Dependency Injection: Riverpod. Shared OSRM client for live maps.
final routingServiceProvider = Provider<RoutingService>((ref) {
  final service = OsrmRoutingService();
  ref.onDispose(service.dispose);
  return service;
});

/// Typed access to cache helpers used by admin / navigation controllers.
final osrmRoutingServiceProvider = Provider<OsrmRoutingService>((ref) {
  return ref.watch(routingServiceProvider) as OsrmRoutingService;
});

/// Backward-compatible alias.
final osrmRouteServiceProvider = osrmRoutingServiceProvider;

/// Pickup / destination coordinates resolved from linked requests + places.
class TripMapPlaces {
  const TripMapPlaces({this.pickup, this.destination});

  final Place? pickup;
  final Place? destination;

  LatLng? get pickupPoint {
    final place = pickup;
    if (place == null || !place.hasCoordinates) return null;
    return LatLng(place.latitude!, place.longitude!);
  }

  LatLng? get destinationPoint {
    final place = destination;
    if (place == null || !place.hasCoordinates) return null;
    return LatLng(place.latitude!, place.longitude!);
  }
}

final tripMapPlacesProvider = FutureProvider.autoDispose
    .family<TripMapPlaces, Trip>((ref, trip) async {
      if (trip.requestIds.isEmpty) return const TripMapPlaces();

      List<TripRequest> requests = const [];
      try {
        requests = await ref.watch(
          tripRequestsByIdsProvider(trip.requestIds.join(',')).future,
        );
      } on Object {
        return const TripMapPlaces();
      }
      final places = await ref.watch(allPlacesProvider.future);
      return _resolveTripMapPlaces(requests: requests, places: places);
    });

TripMapPlaces _resolveTripMapPlaces({
  required List<TripRequest> requests,
  required List<Place> places,
}) {
  if (requests.isEmpty) return const TripMapPlaces();

  final byId = {for (final place in places) place.id: place};
  Place? pickup;
  Place? destination;

  for (final request in requests) {
    final pickupId = request.pickupPlaceId;
    final destinationId = request.destinationPlaceId;
    if (pickup == null && pickupId != null) {
      pickup = byId[pickupId];
    }
    if (destination == null && destinationId != null) {
      destination = byId[destinationId];
    }
    if (pickup != null && destination != null) break;
  }

  // Custom / map-picked coordinates on the request win for display.
  Place? pickupOverride = pickup;
  Place? destinationOverride = destination;
  for (final request in requests) {
    if (request.hasCustomPickupLocation &&
        pickupOverride?.hasCoordinates != true) {
      pickupOverride = Place(
        id: request.pickupPlaceId ?? 'custom-pickup',
        nameEn: request.pickupPlaceName,
        nameAr: request.pickupPlaceName,
        isActive: true,
        createdAt: request.createdAt,
        latitude: request.pickupLat,
        longitude: request.pickupLng,
        address: request.pickupAddress,
      );
    } else if (request.pickupLat != null &&
        request.pickupLng != null &&
        pickupOverride?.hasCoordinates != true) {
      pickupOverride = Place(
        id: request.pickupPlaceId ?? 'pickup-coords',
        nameEn: request.pickupPlaceName,
        nameAr: request.pickupPlaceName,
        isActive: true,
        createdAt: request.createdAt,
        latitude: request.pickupLat,
        longitude: request.pickupLng,
        address: request.pickupAddress,
      );
    }

    if (request.hasCustomDestinationLocation &&
        destinationOverride?.hasCoordinates != true) {
      destinationOverride = Place(
        id: request.destinationPlaceId ?? 'custom-destination',
        nameEn: request.destinationPlaceName,
        nameAr: request.destinationPlaceName,
        isActive: true,
        createdAt: request.createdAt,
        latitude: request.destinationLat,
        longitude: request.destinationLng,
        address: request.destinationAddress,
      );
    } else if (request.destinationLat != null &&
        request.destinationLng != null &&
        destinationOverride?.hasCoordinates != true) {
      destinationOverride = Place(
        id: request.destinationPlaceId ?? 'destination-coords',
        nameEn: request.destinationPlaceName,
        nameAr: request.destinationPlaceName,
        isActive: true,
        createdAt: request.createdAt,
        latitude: request.destinationLat,
        longitude: request.destinationLng,
        address: request.destinationAddress,
      );
    }
  }

  return TripMapPlaces(
    pickup: pickupOverride,
    destination: destinationOverride,
  );
}
