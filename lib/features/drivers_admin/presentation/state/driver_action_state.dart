import 'package:equatable/equatable.dart';
import 'package:teletech_drivers/core/errors/failures.dart';

/// Loading and failure state for driver activation actions.
final class DriverActionState extends Equatable {
  const DriverActionState({
    this.isLoading = false,
    this.failure,
    this.activeDriverId,
  });

  final bool isLoading;
  final Failure? failure;
  final String? activeDriverId;

  @override
  List<Object?> get props => [isLoading, failure, activeDriverId];
}
