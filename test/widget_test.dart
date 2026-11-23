import 'package:flutter_test/flutter_test.dart';
import 'package:teletech_drivers/core/router/app_routes.dart';
import 'package:teletech_drivers/core/router/role_route_strategy.dart';
import 'package:teletech_drivers/features/auth/domain/entities/user_role.dart';

void main() {
  test('admin role routes to admin dashboard', () {
    const strategy = AppRoleRouteStrategy();
    expect(strategy.homeLocation(UserRole.admin), AppRoutes.adminDashboard);
    expect(strategy.canAccess(UserRole.admin, AppRoutes.adminDrivers), isTrue);
  });
}
