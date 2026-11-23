import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:teletech_drivers/core/navigation/role_navigation_config.dart';
import 'package:teletech_drivers/core/presentation/glass_bar_inset.dart';
import 'package:teletech_drivers/core/presentation/glass_bottom_bar.dart';
import 'package:teletech_drivers/features/realtime/presentation/widgets/realtime_connection_indicator.dart';

/// Shell for one role: preserves branch state and paints the glass bottom bar.
class RoleShell extends StatelessWidget {
  const RoleShell({
    required this.navigationShell,
    required this.config,
    this.badgeCounts = const {},
    super.key,
  });

  final StatefulNavigationShell navigationShell;
  final RoleNavigationConfig config;

  /// Pending counts keyed by [NavItem.id]. Shown on that destination.
  final Map<String, int> badgeCounts;

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final totalHeight = keyboardOpen
        ? 0.0
        : GlassBottomBar.barHeight + GlassBottomBar.bottomMargin + safeBottom;
    final branch = navigationShell.currentIndex;
    final moreSelected =
        config.overflow.isNotEmpty && branch >= config.primary.length;
    final selectedIndex = moreSelected ? -1 : branch;

    return GlassBarInset(
      totalHeight: totalHeight,
      child: Scaffold(
        extendBody: true,
        body: Stack(
          children: [
            Positioned.fill(child: navigationShell),
            const PositionedDirectional(
              top: 0,
              end: 0,
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: RealtimeConnectionIndicator(),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: keyboardOpen
            ? null
            : Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  0,
                  16,
                  GlassBottomBar.bottomMargin + safeBottom,
                ),
                child: GlassBottomBar(
                  items: config.primary,
                  selectedIndex: selectedIndex,
                  moreItems: config.overflow,
                  moreSelected: moreSelected,
                  badgeCounts: badgeCounts,
                  onSelected: (index) {
                    navigationShell.goBranch(
                      index,
                      initialLocation: index == navigationShell.currentIndex,
                    );
                  },
                  onMoreSelected: (item) {
                    navigationShell.goBranch(config.branchIndexOf(item.id));
                  },
                ),
              ),
      ),
    );
  }
}
