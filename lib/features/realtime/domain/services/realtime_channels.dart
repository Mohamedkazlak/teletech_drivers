import 'package:teletech_drivers/features/auth/domain/entities/app_user.dart';
import 'package:teletech_drivers/features/auth/domain/entities/user_role.dart';

/// Private channels this signed-in person may join.
List<String> channelsForUser(AppUser user) {
  final personal = 'private-user.${user.id}';
  return switch (user.role) {
    UserRole.admin => ['private-role.admin', personal],
    UserRole.companyAdmin => ['private-role.company-admin', personal],
    UserRole.driversAdmin => ['private-role.drivers-admin', personal],
    UserRole.driver || UserRole.employee => [personal],
  };
}
