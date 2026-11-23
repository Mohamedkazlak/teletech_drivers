import 'package:equatable/equatable.dart';
import 'package:teletech_drivers/core/errors/failures.dart';

/// Loading and failure state for trip request mutations.
final class TripRequestFormState extends Equatable {
  const TripRequestFormState({
    this.isLoading = false,
    this.failure,
    this.activeRequestId,
    this.createdTripId,
  });

  final bool isLoading;
  final Failure? failure;

  /// When cancelling, the request id currently being updated.
  final String? activeRequestId;

  /// Set after Drivers Admin self-request creates an unassigned trip.
  final String? createdTripId;

  @override
  List<Object?> get props => [
    isLoading,
    failure,
    activeRequestId,
    createdTripId,
  ];
}
