import 'package:teletech_drivers/features/trip/domain/entities/trip_draft.dart';
import 'package:teletech_drivers/features/trip/domain/strategies/trip_grouping_strategy.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request.dart';

/// Strategy: all selected requests become a single trip.
final class GroupedRequests implements TripGroupingStrategy {
  const GroupedRequests();

  @override
  List<TripDraft> group(List<TripRequest> requests, {DateTime? scheduledAt}) {
    if (requests.isEmpty) return const [];
    if (scheduledAt == null) {
      throw ArgumentError('scheduledAt is required when grouping requests');
    }

    return [
      TripDraft(
        requestIds: [for (final request in requests) request.id],
        passengerIds: [for (final request in requests) request.employeeId],
        passengerNames: [for (final request in requests) request.employeeName],
        passengerBranches: [
          for (final request in requests) request.employeeBranch,
        ],
        pickupSummary: _summarize([
          for (final request in requests) request.pickupPlaceName,
        ]),
        destinationSummary: _summarize([
          for (final request in requests) request.destinationPlaceName,
        ]),
        scheduledAt: scheduledAt,
      ),
    ];
  }

  static String _summarize(List<String> values) {
    final unique = <String>{};
    final ordered = <String>[];
    for (final value in values) {
      if (unique.add(value)) {
        ordered.add(value);
      }
    }
    return ordered.join(' · ');
  }
}
