import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/errors/failures.dart';
import 'package:teletech_drivers/features/admin/presentation/providers/employee_providers.dart';
import 'package:teletech_drivers/features/admin/presentation/state/employee_form_state.dart';
import 'package:teletech_drivers/features/auth/domain/entities/branch.dart';

final createEmployeeControllerProvider =
    NotifierProvider.autoDispose<CreateEmployeeController, EmployeeFormState>(
      CreateEmployeeController.new,
    );

class CreateEmployeeController extends Notifier<EmployeeFormState> {
  @override
  EmployeeFormState build() => const EmployeeFormState();

  Future<bool> submit({
    required String nameEn,
    required String nameAr,
    required String email,
    required String password,
    required String phone,
    required Branch branch,
  }) async {
    if (state.isLoading) return false;
    state = const EmployeeFormState(isLoading: true);
    try {
      await ref.read(createEmployeeUseCaseProvider)(
        nameEn: nameEn.trim(),
        nameAr: nameAr.trim(),
        email: email.trim(),
        password: password,
        phone: phone.trim(),
        branch: branch,
      );
      if (!ref.mounted) return false;
      state = const EmployeeFormState();
      return true;
    } on Failure catch (failure) {
      if (!ref.mounted) return false;
      state = EmployeeFormState(failure: failure);
      return false;
    } on Object {
      if (!ref.mounted) return false;
      state = const EmployeeFormState(failure: UnknownFailure());
      return false;
    }
  }
}
