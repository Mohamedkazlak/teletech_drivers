import 'package:equatable/equatable.dart';
import 'package:teletech_drivers/core/errors/failures.dart';

/// Loading, field errors, and outcome of the change-password form.
final class ChangePasswordState extends Equatable {
  const ChangePasswordState({
    this.isLoading = false,
    this.failure,
    this.fieldErrors = const {},
    this.saved = false,
  });

  final bool isLoading;
  final Failure? failure;
  final Map<String, String> fieldErrors;
  final bool saved;

  bool get rateLimited =>
      failure is AuthFailure &&
      (failure! as AuthFailure).kind == AuthErrorKind.tooManyRequests;

  @override
  List<Object?> get props => [isLoading, failure, fieldErrors, saved];
}
