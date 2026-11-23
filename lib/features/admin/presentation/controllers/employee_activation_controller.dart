import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/errors/failures.dart';
import 'package:teletech_drivers/features/admin/presentation/providers/employee_providers.dart';
import 'package:teletech_drivers/features/admin/presentation/state/employee_action_state.dart';

final employeeActivationControllerProvider =
    NotifierProvider.autoDispose<
      EmployeeActivationController,
      EmployeeActionState
    >(EmployeeActivationController.new);

class EmployeeActivationController extends Notifier<EmployeeActionState> {
  @override
  EmployeeActionState build() => const EmployeeActionState();

  Future<bool> setActive({
    required String employeeId,
    required bool isActive,
  }) async {
    if (state.isLoading) return false;
    state = EmployeeActionState(
      isLoading: true,
      activeEmployeeId: employeeId,
    );
    try {
      await ref.read(setEmployeeActiveUseCaseProvider)(
        employeeId: employeeId,
        isActive: isActive,
      );
      if (!ref.mounted) return false;
      state = const EmployeeActionState();
      return true;
    } on Failure catch (failure) {
      if (!ref.mounted) return false;
      state = EmployeeActionState(failure: failure);
      return false;
    } on Object {
      if (!ref.mounted) return false;
      state = const EmployeeActionState(failure: UnknownFailure());
      return false;
    }
  }
}
