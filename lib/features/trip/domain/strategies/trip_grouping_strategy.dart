import 'package:teletech_drivers/features/trip/domain/entities/trip_draft.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request.dart';

/// Strategy: how selected pending requests become trip drafts.
abstract interface class TripGroupingStrategy {
  /// Builds one or more drafts from [requests].
  ///
  /// [scheduledAt] is required for strategies that share a single schedule
  /// across multiple requests; ignored when each request keeps its own time.
  List<TripDraft> group(List<TripRequest> requests, {DateTime? scheduledAt});
}
