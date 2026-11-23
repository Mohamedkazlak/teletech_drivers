import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/errors/failures.dart';
import 'package:teletech_drivers/features/admin/presentation/providers/employee_providers.dart';
import 'package:teletech_drivers/features/admin/presentation/state/employee_action_state.dart';

final employeeSoftDeleteControllerProvider =
    NotifierProvider.autoDispose<
      EmployeeSoftDeleteController,
      EmployeeActionState
    >(EmployeeSoftDeleteController.new);

class EmployeeSoftDeleteController extends Notifier<EmployeeActionState> {
  @override
  EmployeeActionState build() => const EmployeeActionState();

  Future<bool> softDelete({
    required String employeeId,
    required String deletedBy,
  }) async {
    if (state.isLoading) return false;
    state = EmployeeActionState(
      isLoading: true,
      activeEmployeeId: employeeId,
    );
    try {
      await ref.read(softDeleteEmployeeUseCaseProvider)(
        employeeId: employeeId,
        deletedBy: deletedBy,
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
