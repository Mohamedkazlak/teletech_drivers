import 'package:teletech_drivers/features/tracking/domain/entities/tracked_location_point.dart';

/// Track phase accumulated on-device (going vs return counted separately).
enum TripTrackPhase { going, returning }

/// Result of encoding a finished going/return segment for a phase upload.
class PhaseTrackSnapshot {
  const PhaseTrackSnapshot({
    required this.phase,
    required this.encodedPolyline,
    required this.distanceMeters,
    required this.points,
  });

  final TripTrackPhase phase;
  final String encodedPolyline;
  final double distanceMeters;
  final List<TrackedLocationPoint> points;
}

/// Outcome of the permission / services gate before tracking starts.
enum LocationPermissionOutcome {
  granted,
  denied,
  permanentlyDenied,
  servicesDisabled,
}

/// Interface: testable GPS + phase distance pipeline (Repository/Strategy).
abstract interface class LocationTrackingService {
  /// Filtered accepted points for the active phase (Observer).
  Stream<TrackedLocationPoint> get acceptedLocations;

  String? get activeTripId;
  TripTrackPhase? get activePhase;
  bool get isTracking;
  List<TrackedLocationPoint> get acceptedPoints;
  double get distanceMeters;

  Future<LocationPermissionOutcome> ensurePermissions();

  Future<void> openAppSettings();

  Future<void> openLocationSettings();

  /// Starts foreground GPS for [tripId] / [phase], restoring local points
  /// when resuming after a crash.
  Future<void> startTracking({
    required String tripId,
    required TripTrackPhase phase,
  });

  /// Clears the current phase buffer and starts accumulating for [phase].
  Future<void> switchPhase(TripTrackPhase phase);

  Future<void> stopTracking();

  /// Encodes the current phase track; does not clear until [clearPhaseBuffer].
  PhaseTrackSnapshot finalizeCurrentPhase();

  Future<void> clearPhaseBuffer();
}
