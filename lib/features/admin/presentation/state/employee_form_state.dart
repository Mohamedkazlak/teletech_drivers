import 'package:teletech_drivers/core/errors/failures.dart';

class EmployeeFormState {
  const EmployeeFormState({this.isLoading = false, this.failure});

  final bool isLoading;
  final Failure? failure;
}
