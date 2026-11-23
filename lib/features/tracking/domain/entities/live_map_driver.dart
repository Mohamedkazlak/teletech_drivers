import 'package:equatable/equatable.dart';
import 'package:teletech_drivers/features/auth/domain/entities/app_user.dart';
import 'package:teletech_drivers/features/tracking/domain/entities/live_map_state.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_status.dart';

/// Trip fields returned with a live-map row.
class LiveMapTripSummary extends Equatable {
  const LiveMapTripSummary({
    required this.id,
    required this.status,
    required this.pickupSummary,
    required this.destinationSummary,
    this.scheduledAt,
    this.goingStartedAt,
  });

  final String id;
  final TripStatus status;
  final String pickupSummary;
  final String destinationSummary;
  final DateTime? scheduledAt;
  final DateTime? goingStartedAt;

  @override
  List<Object?> get props => [
    id,
    status,
    pickupSummary,
    destinationSummary,
    scheduledAt,
    goingStartedAt,
  ];
}

/// One driver on the Drivers Admin live map.
///
/// [isStale] comes from the server. Coordinates may be null when no fix exists.
class LiveMapDriver extends Equatable {
  const LiveMapDriver({
    required this.driver,
    required this.isStale,
    required this.isTracking,
    required this.state,
    this.trip,
    this.lat,
    this.lng,
    this.heading,
    this.speed,
    this.accuracy,
    this.updatedAt,
    this.lastSeenAt,
  });

  final AppUser driver;
  final LiveMapState state;
  final LiveMapTripSummary? trip;
  final double? lat;
  final double? lng;
  final double? heading;
  final double? speed;
  final double? accuracy;
  final DateTime? updatedAt;

  /// Server `last_seen_at`, falling back to [updatedAt].
  final DateTime? lastSeenAt;
  final bool isStale;
  final bool isTracking;

  bool get hasFix => lat != null && lng != null;

  @override
  List<Object?> get props => [
    driver,
    trip,
    lat,
    lng,
    heading,
    speed,
    accuracy,
    updatedAt,
    lastSeenAt,
    state,
    isStale,
    isTracking,
  ];
}
