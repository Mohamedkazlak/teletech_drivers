import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/features/trip/presentation/controllers/created_by_me_trips_controller.dart';
import 'package:teletech_drivers/features/trip/presentation/providers/trip_providers.dart';

/// Refreshes every trip list, detail, report and recommendation provider after
/// a trip mutation. Only providers that are currently listened to refetch.
void invalidateTripProviders(Ref ref) {
  ref
    ..invalidate(allTripsProvider)
    ..invalidate(tripsQueryProvider)
    ..invalidate(driverTripsProvider)
    ..invalidate(tripByIdProvider)
    ..invalidate(watchTripByIdProvider)
    ..invalidate(tripReportProvider)
    ..invalidate(driverRecommendationsProvider)
    ..invalidate(createdByMeTripsProvider);
}
