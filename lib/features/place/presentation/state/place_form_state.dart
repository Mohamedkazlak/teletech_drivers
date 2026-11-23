import 'package:equatable/equatable.dart';
import 'package:teletech_drivers/core/errors/failures.dart';

/// Loading and failure state for place form mutations.
final class PlaceFormState extends Equatable {
  const PlaceFormState({this.isLoading = false, this.failure});

  final bool isLoading;
  final Failure? failure;

  @override
  List<Object?> get props => [isLoading, failure];
}
