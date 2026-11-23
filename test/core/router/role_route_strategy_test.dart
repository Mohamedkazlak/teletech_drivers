import 'package:flutter_test/flutter_test.dart';
import 'package:teletech_drivers/core/router/app_routes.dart';
import 'package:teletech_drivers/core/router/role_route_strategy.dart';
import 'package:teletech_drivers/features/auth/domain/entities/user_role.dart';

void main() {
  const strategy = AppRoleRouteStrategy();

  group('AppRoleRouteStrategy', () {
    test('admin home is dashboard', () {
      expect(strategy.homeLocation(UserRole.admin), AppRoutes.adminDashboard);
    });

    test('admin can access all /admin/* routes', () {
      expect(
        strategy.canAccess(UserRole.admin, AppRoutes.adminDashboard),
        isTrue,
      );
      expect(
        strategy.canAccess(UserRole.admin, AppRoutes.adminDrivers),
        isTrue,
      );
      expect(strategy.canAccess(UserRole.admin, AppRoutes.adminPlaces), isTrue);
      expect(
        strategy.canAccess(UserRole.admin, AppRoutes.adminEmployees),
        isTrue,
      );
      expect(
        strategy.canAccess(UserRole.admin, AppRoutes.adminMyTrips),
        isTrue,
      );
      expect(strategy.canAccess(UserRole.admin, '/admin/drivers/d1'), isTrue);
    });

    test('other roles cannot access /admin/*', () {
      for (final role in [
        UserRole.companyAdmin,
        UserRole.driversAdmin,
        UserRole.driver,
        UserRole.employee,
      ]) {
        expect(strategy.canAccess(role, AppRoutes.adminDashboard), isFalse);
        expect(strategy.canAccess(role, AppRoutes.adminDrivers), isFalse);
      }
    });

    test('admin cannot access other role homes', () {
      expect(
        strategy.canAccess(UserRole.admin, AppRoutes.companyAdminHome),
        isFalse,
      );
      expect(
        strategy.canAccess(UserRole.admin, AppRoutes.driversAdminHome),
        isFalse,
      );
    });
  });
}
