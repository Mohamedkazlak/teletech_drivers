import 'package:teletech_drivers/features/trip/domain/entities/trip.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_status.dart';

/// True when [status] is going, at the destination, or returning.
bool tripStatusBlocksAvailability(TripStatus status) => status.isInProgress;

/// True when [driverId] has any in-progress trip in [trips].
bool driverHasActiveTrip({
  required String driverId,
  required Iterable<Trip> trips,
}) {
  for (final trip in trips) {
    if (trip.driverId == driverId &&
        tripStatusBlocksAvailability(trip.status)) {
      return true;
    }
  }
  return false;
}
