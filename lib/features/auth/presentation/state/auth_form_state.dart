import 'package:equatable/equatable.dart';
import 'package:teletech_drivers/core/errors/failures.dart';

/// Loading and failure state shared by the auth forms.
final class AuthFormState extends Equatable {
  const AuthFormState({this.isLoading = false, this.failure});

  final bool isLoading;
  final Failure? failure;

  @override
  List<Object?> get props => [isLoading, failure];
}
