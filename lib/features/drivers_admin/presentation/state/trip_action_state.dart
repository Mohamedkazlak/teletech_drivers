import 'package:equatable/equatable.dart';
import 'package:teletech_drivers/core/errors/failures.dart';

/// Loading and failure state for trip assign / reassign / cancel.
final class TripActionState extends Equatable {
  const TripActionState({
    this.isLoading = false,
    this.failure,
    this.activeTripId,
  });

  final bool isLoading;
  final Failure? failure;
  final String? activeTripId;

  @override
  List<Object?> get props => [isLoading, failure, activeTripId];
}
