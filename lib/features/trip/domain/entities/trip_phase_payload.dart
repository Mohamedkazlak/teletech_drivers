import 'package:teletech_drivers/features/tracking/domain/services/location_tracking_service.dart';

/// Data attached when starting the going phase.
class StartTripPayload {
  const StartTripPayload({required this.startLat, required this.startLng});

  final double startLat;
  final double startLng;
}

/// Going-phase track written when the driver arrives at destination.
class ArriveDestinationPayload {
  const ArriveDestinationPayload({
    required this.goingRoute,
    required this.goingDistanceMeters,
  });

  final String goingRoute;
  final double goingDistanceMeters;

  factory ArriveDestinationPayload.fromSnapshot(PhaseTrackSnapshot snapshot) {
    return ArriveDestinationPayload(
      goingRoute: snapshot.encodedPolyline,
      goingDistanceMeters: snapshot.distanceMeters,
    );
  }
}

/// Return-phase track written when the driver ends the trip.
class EndTripPayload {
  const EndTripPayload({
    required this.returnRoute,
    required this.returnDistanceMeters,
    required this.goingDistanceMeters,
  });

  final String returnRoute;
  final double returnDistanceMeters;
  final double goingDistanceMeters;

  double get totalDistanceMeters => goingDistanceMeters + returnDistanceMeters;

  factory EndTripPayload.fromSnapshot({
    required PhaseTrackSnapshot snapshot,
    required double goingDistanceMeters,
  }) {
    return EndTripPayload(
      returnRoute: snapshot.encodedPolyline,
      returnDistanceMeters: snapshot.distanceMeters,
      goingDistanceMeters: goingDistanceMeters,
    );
  }
}
