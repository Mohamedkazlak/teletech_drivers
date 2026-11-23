import 'package:teletech_drivers/features/drivers_admin/domain/entities/driver_recommendation.dart';
import 'package:teletech_drivers/features/trip/domain/entities/created_trip_bucket.dart';
import 'package:teletech_drivers/features/trip/domain/entities/mine_trips_filter.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_list_query.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_page.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_phase_payload.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_report.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_status.dart';
import 'package:teletech_drivers/features/trip/domain/strategies/trip_grouping_strategy.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request.dart';

/// Repository: company trips.
abstract interface class TripRepository {
  /// Creates trip(s) from approved [requests] and links them in one server call.
  Future<List<Trip>> createTripsFromRequests({
    required List<TripRequest> requests,
    required TripGroupingStrategy strategy,
    required String createdBy,
    DateTime? scheduledAt,
  });

  /// Observer: every trip, newest [Trip.createdAt] first.
  Stream<List<Trip>> watchAllTrips();

  /// Observer: trips matching [query] (`stage` and `branch` query params).
  Stream<List<Trip>> watchTrips(TripListQuery query);

  /// One page of trips the signed-in user created.
  Future<TripPage> listCreatedByMe({
    required CreatedTripBucket bucket,
    required int page,
  });

  /// Observer: trips with the given [status], newest first.
  Stream<List<Trip>> watchTripsByStatus(TripStatus status);

  /// Observer: trips assigned to [driverId], ordered by scheduled time.
  Stream<List<Trip>> watchTripsByDriver(String driverId);

  /// Observer: the signed-in driver's trips for [filter] (`/trips/mine`).
  Stream<List<Trip>> watchMyTrips(MineTripsFilter filter);

  /// Loads a single trip by id, or null when missing.
  Future<Trip?> getTripById(String tripId);

  /// Observer: a single trip document, or null when missing / deleted.
  Stream<Trip?> watchTripById(String tripId);

  /// Assigns [driverId] to an unassigned trip in a transaction that confirms
  /// the trip is still unassigned, then sets status to assigned.
  Future<void> assignDriver({required String tripId, required String driverId});

  /// Changes the driver while the trip remains [TripStatus.assigned].
  Future<void> reassignDriver({
    required String tripId,
    required String driverId,
  });

  /// Cancels a trip that has not started (unassigned or assigned only).
  Future<void> cancelTrip(String tripId);

  /// State: assigned → going; sets goingStartedAt + start coordinates.
  Future<void> startTrip({
    required String tripId,
    required StartTripPayload payload,
  });

  /// State: going → atDestination; saves going route + distance in one write.
  Future<void> arriveAtDestination({
    required String tripId,
    required ArriveDestinationPayload payload,
  });

  /// State: atDestination → returning; sets returnStartedAt.
  Future<void> startReturn(String tripId);

  /// State: returning → completed; saves return route + distances in one write.
  Future<void> endTrip({
    required String tripId,
    required EndTripPayload payload,
  });

  /// Server-built report for [tripId] (durations, distances, route geometry).
  Future<TripReport> getTripReport(String tripId);

  /// Server-ranked driver candidates for assigning or reassigning [tripId].
  Future<List<DriverRecommendation>> getDriverRecommendations(String tripId);
}
