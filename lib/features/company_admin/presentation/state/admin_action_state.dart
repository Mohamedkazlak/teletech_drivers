import 'package:equatable/equatable.dart';
import 'package:teletech_drivers/core/errors/failures.dart';

/// Loading and failure state for company-admin mutations.
final class AdminActionState extends Equatable {
  const AdminActionState({
    this.isLoading = false,
    this.failure,
    this.activeRequestId,
  });

  final bool isLoading;
  final Failure? failure;
  final String? activeRequestId;

  @override
  List<Object?> get props => [isLoading, failure, activeRequestId];
}
