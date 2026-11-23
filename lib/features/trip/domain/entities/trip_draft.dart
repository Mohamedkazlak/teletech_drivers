import 'package:equatable/equatable.dart';
import 'package:teletech_drivers/features/auth/domain/entities/branch.dart';

/// Values prepared by a [TripGroupingStrategy] before persistence.
class TripDraft extends Equatable {
  const TripDraft({
    required this.requestIds,
    required this.passengerIds,
    required this.passengerNames,
    required this.passengerBranches,
    required this.pickupSummary,
    required this.destinationSummary,
    required this.scheduledAt,
  });

  final List<String> requestIds;
  final List<String> passengerIds;
  final List<String> passengerNames;
  final List<Branch?> passengerBranches;
  final String pickupSummary;
  final String destinationSummary;
  final DateTime scheduledAt;

  @override
  List<Object?> get props => [
    requestIds,
    passengerIds,
    passengerNames,
    passengerBranches,
    pickupSummary,
    destinationSummary,
    scheduledAt,
  ];
}
