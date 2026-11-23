import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/features/admin/data/providers/employee_repository_provider.dart';
import 'package:teletech_drivers/features/admin/domain/use_cases/create_employee.dart';
import 'package:teletech_drivers/features/admin/domain/use_cases/get_employee.dart';
import 'package:teletech_drivers/features/admin/domain/use_cases/set_employee_active.dart';
import 'package:teletech_drivers/features/admin/domain/use_cases/soft_delete_employee.dart';
import 'package:teletech_drivers/features/admin/domain/use_cases/update_employee.dart';
import 'package:teletech_drivers/features/admin/domain/use_cases/watch_all_employees.dart';
import 'package:teletech_drivers/features/auth/domain/entities/app_user.dart';
import 'package:teletech_drivers/features/auth/presentation/providers/auth_bound_stream.dart';

final watchAllEmployeesUseCaseProvider = Provider<WatchAllEmployeesUseCase>((
  ref,
) {
  return WatchAllEmployeesUseCase(ref.watch(employeeRepositoryProvider));
});

final getEmployeeUseCaseProvider = Provider<GetEmployeeUseCase>((ref) {
  return GetEmployeeUseCase(ref.watch(employeeRepositoryProvider));
});

final createEmployeeUseCaseProvider = Provider<CreateEmployeeUseCase>((ref) {
  return CreateEmployeeUseCase(ref.watch(employeeRepositoryProvider));
});

final updateEmployeeUseCaseProvider = Provider<UpdateEmployeeUseCase>((ref) {
  return UpdateEmployeeUseCase(ref.watch(employeeRepositoryProvider));
});

final softDeleteEmployeeUseCaseProvider = Provider<SoftDeleteEmployeeUseCase>((
  ref,
) {
  return SoftDeleteEmployeeUseCase(ref.watch(employeeRepositoryProvider));
});

final setEmployeeActiveUseCaseProvider = Provider<SetEmployeeActiveUseCase>((
  ref,
) {
  return SetEmployeeActiveUseCase(ref.watch(employeeRepositoryProvider));
});

/// Observer: all employees for admin list screens.
final allEmployeesProvider = StreamProvider.autoDispose<List<AppUser>>((ref) {
  return authBoundStream(
    ref,
    whenSignedOut: const <AppUser>[],
    create: (_) => ref.watch(watchAllEmployeesUseCaseProvider)(),
  );
}, retry: (_, _) => null);

/// Active employees only (dropdowns / pickers).
final activeEmployeesProvider =
    Provider.autoDispose<AsyncValue<List<AppUser>>>((ref) {
      return ref
          .watch(allEmployeesProvider)
          .whenData(
            (employees) =>
                employees.where((employee) => employee.isActive).toList(),
          );
    });

final employeeProvider = FutureProvider.autoDispose.family<AppUser, String>((
  ref,
  employeeId,
) {
  return ref.watch(getEmployeeUseCaseProvider)(employeeId);
});
