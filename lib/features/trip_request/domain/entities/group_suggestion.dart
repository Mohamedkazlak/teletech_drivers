import 'package:equatable/equatable.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request.dart';

/// A cluster of same-day, same-destination requests suggested for joining.
class GroupSuggestion extends Equatable {
  const GroupSuggestion({
    required this.clusterId,
    required this.requests,
    required this.routeLabel,
    required this.earliestDateTime,
    required this.latestDateTime,
  });

  /// Stable id derived from the member request ids (usable as suggestedGroupId).
  final String clusterId;

  /// Member requests (size >= 2), sorted by [TripRequest.requestedDateTime].
  final List<TripRequest> requests;

  /// Shared route summary, e.g. "HQ → Airport" or just "Airport".
  final String routeLabel;

  /// Earliest [TripRequest.requestedDateTime] in the cluster.
  final DateTime earliestDateTime;

  /// Latest [TripRequest.requestedDateTime] in the cluster.
  final DateTime latestDateTime;

  int get size => requests.length;

  @override
  List<Object?> get props => [
    clusterId,
    requests,
    routeLabel,
    earliestDateTime,
    latestDateTime,
  ];
}
