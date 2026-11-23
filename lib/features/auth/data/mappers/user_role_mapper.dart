import 'package:teletech_drivers/features/auth/domain/entities/user_role.dart';

/// Maps Laravel role strings (`company_admin`) ↔ Flutter [UserRole] names.
abstract final class UserRoleMapper {
  static const companyAdminApi = 'company_admin';
  static const driversAdminApi = 'drivers_admin';

  static UserRole fromApi(String value) {
    return switch (value.trim()) {
      'admin' => UserRole.admin,
      companyAdminApi => UserRole.companyAdmin,
      driversAdminApi => UserRole.driversAdmin,
      'driver' => UserRole.driver,
      'employee' => UserRole.employee,
      _ => throw FormatException('Unknown role: $value'),
    };
  }

  static String toApi(UserRole role) {
    return switch (role) {
      UserRole.admin => 'admin',
      UserRole.companyAdmin => companyAdminApi,
      UserRole.driversAdmin => driversAdminApi,
      UserRole.driver => 'driver',
      UserRole.employee => 'employee',
    };
  }
}
