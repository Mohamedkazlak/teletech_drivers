import 'package:teletech_drivers/features/trip/domain/entities/trip_draft.dart';
import 'package:teletech_drivers/features/trip/domain/strategies/trip_grouping_strategy.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request.dart';

/// Strategy: each selected request becomes its own trip.
final class OneRequestPerTrip implements TripGroupingStrategy {
  const OneRequestPerTrip();

  @override
  List<TripDraft> group(List<TripRequest> requests, {DateTime? scheduledAt}) {
    return [
      for (final request in requests)
        TripDraft(
          requestIds: [request.id],
          passengerIds: [request.employeeId],
          passengerNames: [request.employeeName],
          passengerBranches: [request.employeeBranch],
          pickupSummary: request.pickupPlaceName,
          destinationSummary: request.destinationPlaceName,
          scheduledAt: request.requestedDateTime,
        ),
    ];
  }
}
