import 'package:equatable/equatable.dart';
import 'package:teletech_drivers/core/errors/failures.dart';

/// Loading and failure state for the legacy-driver backfill action.
final class FixLegacyDriversState extends Equatable {
  const FixLegacyDriversState({this.isLoading = false, this.failure});

  final bool isLoading;
  final Failure? failure;

  @override
  List<Object?> get props => [isLoading, failure];
}
