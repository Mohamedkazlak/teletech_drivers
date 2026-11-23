import 'package:equatable/equatable.dart';
import 'package:teletech_drivers/core/errors/failures.dart';

/// Loading, field errors, and outcome of the profile form.
final class ProfileFormState extends Equatable {
  const ProfileFormState({
    this.isLoading = false,
    this.failure,
    this.fieldErrors = const {},
    this.saved = false,
  });

  final bool isLoading;
  final Failure? failure;
  final Map<String, String> fieldErrors;
  final bool saved;

  @override
  List<Object?> get props => [isLoading, failure, fieldErrors, saved];
}
