import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';
import 'package:teletech_drivers/core/errors/failures.dart';

enum LocationTrackingStatus {
  idle,
  requestingPermission,
  sharing,
  permissionDenied,
  permissionPermanentlyDenied,
  servicesDisabled,
  error,
}

/// State: driver-side GPS sharing lifecycle.
class LocationTrackingState extends Equatable {
  const LocationTrackingState({
    this.status = LocationTrackingStatus.idle,
    this.tripId,
    this.position,
    this.failure,
    this.warningBanner = false,
  });

  final LocationTrackingStatus status;
  final String? tripId;
  final Position? position;
  final Failure? failure;
  final bool warningBanner;

  bool get isSharing => status == LocationTrackingStatus.sharing;

  bool get needsSettings =>
      status == LocationTrackingStatus.permissionPermanentlyDenied ||
      status == LocationTrackingStatus.servicesDisabled;

  LocationTrackingState copyWith({
    LocationTrackingStatus? status,
    String? tripId,
    Position? position,
    Failure? failure,
    bool? warningBanner,
    bool clearTripId = false,
    bool clearPosition = false,
    bool clearFailure = false,
  }) {
    return LocationTrackingState(
      status: status ?? this.status,
      tripId: clearTripId ? null : (tripId ?? this.tripId),
      position: clearPosition ? null : (position ?? this.position),
      failure: clearFailure ? null : (failure ?? this.failure),
      warningBanner: warningBanner ?? this.warningBanner,
    );
  }

  @override
  List<Object?> get props => [status, tripId, position, failure, warningBanner];
}
