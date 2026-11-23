import 'package:teletech_drivers/core/errors/failures.dart';

class EmployeeActionState {
  const EmployeeActionState({
    this.isLoading = false,
    this.activeEmployeeId,
    this.failure,
  });

  final bool isLoading;
  final String? activeEmployeeId;
  final Failure? failure;
}
