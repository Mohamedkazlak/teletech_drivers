import 'package:teletech_drivers/core/router/app_routes.dart';
import 'package:teletech_drivers/features/auth/domain/entities/user_role.dart';

/// Strategy: maps a [UserRole] to the routes that role may open.
abstract interface class RoleRouteStrategy {
  String homeLocation(UserRole role);

  bool canAccess(UserRole role, String location);
}

final class AppRoleRouteStrategy implements RoleRouteStrategy {
  const AppRoleRouteStrategy();

  static const _adminPrefix = '/admin';

  @override
  String homeLocation(UserRole role) {
    return switch (role) {
      UserRole.admin => AppRoutes.adminDashboard,
      UserRole.companyAdmin => AppRoutes.companyAdminHome,
      UserRole.driversAdmin => AppRoutes.driversAdminHome,
      UserRole.driver => AppRoutes.driverHome,
      UserRole.employee => AppRoutes.employeeHome,
    };
  }

  @override
  bool canAccess(UserRole role, String location) {
    if (location == AppRoutes.completeProfile) return true;
    if (role == UserRole.admin) {
      return location == _adminPrefix || location.startsWith('$_adminPrefix/');
    }
    final home = homeLocation(role);
    return location == home || location.startsWith('$home/');
  }
}
