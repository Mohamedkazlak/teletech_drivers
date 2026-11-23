import 'package:teletech_drivers/core/errors/failures.dart';

class ResetPasswordState {
  const ResetPasswordState({this.isLoading = false, this.failure});

  final bool isLoading;
  final Failure? failure;
}
