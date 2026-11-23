import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/features/trip_request/presentation/providers/trip_request_providers.dart';

/// Refreshes every trip-request list, detail and grouping provider after a
/// request mutation. Only providers that are currently listened to refetch.
void invalidateTripRequestProviders(Ref ref) {
  ref
    ..invalidate(employeeTripRequestsProvider)
    ..invalidate(myTripRequestsProvider)
    ..invalidate(awaitingConfirmationProvider)
    ..invalidate(pendingTripRequestsProvider)
    ..invalidate(approvedAwaitingTripRequestsProvider)
    ..invalidate(allTripRequestsProvider)
    ..invalidate(adminTripRequestsProvider)
    ..invalidate(tripRequestByIdProvider)
    ..invalidate(watchTripRequestByIdProvider)
    ..invalidate(tripRequestsByIdsProvider)
    ..invalidate(pendingGroupingSuggestionsProvider)
    ..invalidate(approvedGroupingSuggestionsProvider);
}
