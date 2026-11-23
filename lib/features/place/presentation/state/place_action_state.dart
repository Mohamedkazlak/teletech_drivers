import 'package:equatable/equatable.dart';
import 'package:teletech_drivers/core/errors/failures.dart';

/// Loading and failure state for place activation / seed actions.
final class PlaceActionState extends Equatable {
  const PlaceActionState({
    this.isLoading = false,
    this.failure,
    this.activePlaceId,
  });

  final bool isLoading;
  final Failure? failure;

  /// When toggling active, the place id currently being updated.
  final String? activePlaceId;

  @override
  List<Object?> get props => [isLoading, failure, activePlaceId];
}
