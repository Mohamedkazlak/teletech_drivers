import 'package:teletech_drivers/features/auth/domain/entities/app_user.dart';
import 'package:teletech_drivers/features/auth/domain/entities/branch.dart';

/// Repository: employee accounts managed by the system admin.
abstract interface class EmployeeRepository {
  /// Observer: all employee profiles (active and inactive).
  Stream<List<AppUser>> watchAllEmployees();

  Future<AppUser> getEmployee(String employeeId);

  /// Creates the employee account through the API. The admin session stays signed in.
  Future<void> createEmployee({
    required String nameEn,
    required String nameAr,
    required String email,
    required String password,
    required String phone,
    required Branch branch,
  });

  Future<void> updateEmployee({
    required String employeeId,
    required String nameEn,
    required String nameAr,
    required String phone,
    required Branch branch,
  });

  /// Soft delete: isActive=false + deletedAt/deletedBy.
  Future<void> softDeleteEmployee({
    required String employeeId,
    required String deletedBy,
  });

  Future<void> setEmployeeActive({
    required String employeeId,
    required bool isActive,
  });
}
