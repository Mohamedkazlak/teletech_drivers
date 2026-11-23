import 'package:geocoding/geocoding.dart';
import 'package:teletech_drivers/features/place/domain/entities/place.dart';
import 'package:teletech_drivers/features/tracking/domain/entities/route_point.dart';
import 'package:teletech_drivers/features/tracking/domain/entities/trip_endpoint.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request.dart';

/// Resolves From / To for a trip without overwriting saved place docs.
class TripEndpointResolver {
  TripEndpointResolver({Geocoding? geocoding})
    : _geocoding = geocoding ?? Geocoding();

  final Geocoding _geocoding;

  Future<TripEndpoints> resolve({
    required Trip trip,
    required List<TripRequest> requests,
    required List<Place> places,
    required String languageCode,
    RoutePoint? driverFallback,
  }) async {
    final byId = {for (final place in places) place.id: place};
    final pickup = await _resolveSide(
      requests: requests,
      placesById: byId,
      languageCode: languageCode,
      tripSummary: trip.pickupSummary,
      customLat: (r) => r.pickupLat,
      customLng: (r) => r.pickupLng,
      placeIdOf: (r) => r.pickupPlaceId,
      nameOf: (r) => r.pickupPlaceName,
      isCustom: (r) => r.hasCustomPickupLocation,
      tripStartFallback: trip.hasStartCoordinates
          ? RoutePoint(trip.startLat!, trip.startLng!)
          : driverFallback,
    );
    final destination = await _resolveSide(
      requests: requests,
      placesById: byId,
      languageCode: languageCode,
      tripSummary: trip.destinationSummary,
      customLat: (r) => r.destinationLat,
      customLng: (r) => r.destinationLng,
      placeIdOf: (r) => r.destinationPlaceId,
      nameOf: (r) => r.destinationPlaceName,
      isCustom: (r) => r.hasCustomDestinationLocation,
    );

    return TripEndpoints(from: pickup, to: destination);
  }

  Future<TripEndpoint> _resolveSide({
    required List<TripRequest> requests,
    required Map<String, Place> placesById,
    required String languageCode,
    required String tripSummary,
    required double? Function(TripRequest) customLat,
    required double? Function(TripRequest) customLng,
    required String? Function(TripRequest) placeIdOf,
    required String Function(TripRequest) nameOf,
    required bool Function(TripRequest) isCustom,
    RoutePoint? tripStartFallback,
  }) async {
    for (final request in requests) {
      if (isCustom(request)) {
        final lat = customLat(request);
        final lng = customLng(request);
        if (_isUsableCoordinate(lat, lng)) {
          return TripEndpoint(
            name: nameOf(request).trim().isEmpty
                ? tripSummary
                : nameOf(request).trim(),
            point: RoutePoint(lat!, lng!),
          );
        }
      }

      final placeId = placeIdOf(request);
      if (placeId != null) {
        final place = placesById[placeId];
        if (place != null) {
          final name = place.displayName(languageCode);
          if (place.hasCoordinates) {
            return TripEndpoint(
              name: name,
              point: RoutePoint(place.latitude!, place.longitude!),
            );
          }
          final geocoded = await _forwardGeocode(name);
          if (geocoded != null) {
            return TripEndpoint(
              name: name,
              point: geocoded,
              isApproximate: true,
            );
          }
          return TripEndpoint(name: name);
        }
      }

      final freeText = nameOf(request).trim();
      if (freeText.isNotEmpty) {
        final lat = customLat(request);
        final lng = customLng(request);
        if (_isUsableCoordinate(lat, lng)) {
          return TripEndpoint(name: freeText, point: RoutePoint(lat!, lng!));
        }
        final geocoded = await _forwardGeocode(freeText);
        if (geocoded != null) {
          return TripEndpoint(
            name: freeText,
            point: geocoded,
            isApproximate: true,
          );
        }
        return TripEndpoint(name: freeText);
      }
    }

    final summary = tripSummary.trim();
    if (tripStartFallback != null) {
      return TripEndpoint(
        name: summary.isEmpty ? 'Start' : summary,
        point: tripStartFallback,
        isDriverFallback: true,
      );
    }

    if (summary.isNotEmpty) {
      final geocoded = await _forwardGeocode(summary);
      if (geocoded != null) {
        return TripEndpoint(
          name: summary,
          point: geocoded,
          isApproximate: true,
        );
      }
      return TripEndpoint(name: summary);
    }

    return const TripEndpoint(name: '');
  }

  Future<RoutePoint?> _forwardGeocode(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;
    try {
      final results = await _geocoding.locationFromAddress(trimmed);
      if (results.isEmpty) return null;
      final first = results.first;
      if (!_isUsableCoordinate(first.latitude, first.longitude)) return null;
      return RoutePoint(first.latitude, first.longitude);
    } on Object {
      return null;
    }
  }

  bool _isUsableCoordinate(double? lat, double? lng) {
    return lat != null &&
        lng != null &&
        lat.isFinite &&
        lng.isFinite &&
        lat >= -90 &&
        lat <= 90 &&
        lng >= -180 &&
        lng <= 180;
  }
}
