import 'package:flutter/widgets.dart';
import 'package:teletech_drivers/core/navigation/nav_label_key.dart';

/// One destination in a role shell. Pure data; the bar does not know roles.
final class NavItem {
  const NavItem({
    required this.id,
    required this.icon,
    required this.labelKey,
    required this.route,
  });

  final String id;
  final IconData icon;
  final NavLabelKey labelKey;
  final String route;
}
