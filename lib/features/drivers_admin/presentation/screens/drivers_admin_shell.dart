import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:teletech_drivers/core/presentation/role_shell.dart';
import 'package:teletech_drivers/core/navigation/role_navigation_config.dart';
import 'package:teletech_drivers/features/auth/domain/entities/user_role.dart';

/// Drivers admin shell. Attendance replaces the old availability-request badge.
class DriversAdminShell extends StatelessWidget {
  const DriversAdminShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return RoleShell(
      navigationShell: navigationShell,
      config: RoleNavigationConfig.forRole(UserRole.driversAdmin),
    );
  }
}
