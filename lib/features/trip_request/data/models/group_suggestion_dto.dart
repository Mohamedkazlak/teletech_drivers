import 'package:equatable/equatable.dart';
import 'package:teletech_drivers/core/constants/api_json_keys.dart';
import 'package:teletech_drivers/core/network/api_json_parsers.dart';

/// API grouping suggestion cluster (`GroupSuggestionResource`).
final class GroupSuggestionDto extends Equatable {
  const GroupSuggestionDto({
    required this.clusterId,
    required this.requestIds,
    required this.routeLabel,
    required this.earliestRequestedAt,
    required this.latestRequestedAt,
    this.destinationLabel,
    this.date,
  });

  final String clusterId;
  final List<String> requestIds;
  final String? destinationLabel;
  final String routeLabel;
  final String? date;
  final DateTime earliestRequestedAt;
  final DateTime latestRequestedAt;

  factory GroupSuggestionDto.fromJson(Map<String, dynamic> json) {
    return GroupSuggestionDto(
      clusterId: ApiJsonParsers.requireNonEmptyString(
        json[ApiJsonKeys.clusterId],
        'cluster_id',
      ),
      requestIds: ApiJsonParsers.stringList(json[ApiJsonKeys.requestIds]),
      destinationLabel: ApiJsonParsers.optionalString(
        json[ApiJsonKeys.destinationLabel],
      ),
      routeLabel:
          ApiJsonParsers.optionalString(json[ApiJsonKeys.routeLabel]) ?? '',
      date: ApiJsonParsers.optionalString(json[ApiJsonKeys.date]),
      earliestRequestedAt: ApiJsonParsers.requireDateTime(
        json[ApiJsonKeys.earliestRequestedAt],
        'earliest_requested_at',
      ),
      latestRequestedAt: ApiJsonParsers.requireDateTime(
        json[ApiJsonKeys.latestRequestedAt],
        'latest_requested_at',
      ),
    );
  }

  @override
  List<Object?> get props => [
    clusterId,
    requestIds,
    destinationLabel,
    routeLabel,
    date,
    earliestRequestedAt,
    latestRequestedAt,
  ];
}
