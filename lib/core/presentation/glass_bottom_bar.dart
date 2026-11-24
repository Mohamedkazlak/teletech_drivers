import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/navigation/nav_ids.dart';
import 'package:teletech_drivers/core/navigation/nav_item.dart';
import 'package:teletech_drivers/core/navigation/nav_label_key.dart';
import 'package:teletech_drivers/core/navigation/nav_labels.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/core/theme/app_motion.dart';
import 'package:teletech_drivers/core/theme/app_theme.dart';

/// Floating frosted navigation pill. Role-agnostic: it only renders [items].
class GlassBottomBar extends StatelessWidget {
  const GlassBottomBar({
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    this.moreItems = const [],
    this.moreSelected = false,
    this.badgeCounts = const {},
    this.onMoreSelected,
    super.key,
  });

  static const barKey = Key('glass-bottom-bar');

  /// Pill height, excluding the outer margin and the safe-area inset.
  static const double barHeight = 64;

  /// Gap between the pill and the screen edge (plus the safe-area inset).
  static const double bottomMargin = 12;

  final List<NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<NavItem> moreItems;
  final bool moreSelected;

  /// Counts keyed by [NavItem.id], for bar items and More-menu rows.
  final Map<String, int> badgeCounts;
  final ValueChanged<NavItem>? onMoreSelected;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.viewInsetsOf(context).bottom > 0) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);
    final showMore = moreItems.isNotEmpty;
    final entries = <({NavItem item, String label, bool selected, int badge, VoidCallback onTap})>[
      for (var index = 0; index < items.length; index++)
        (
          item: items[index],
          label: navLabel(l10n, items[index].labelKey),
          selected: index == selectedIndex && !moreSelected,
          badge: badgeCounts[items[index].id] ?? 0,
          onTap: () => onSelected(index),
        ),
      if (showMore)
        (
          item: const NavItem(
            id: NavIds.more,
            icon: Icons.more_horiz_rounded,
            labelKey: NavLabelKey.more,
            route: '',
          ),
          label: navLabel(l10n, NavLabelKey.more),
          selected: moreSelected,
          badge: 0,
          onTap: () => _openMore(context, l10n),
        ),
    ];
    final anySelected = entries.any((e) => e.selected);

    return DecoratedBox(
      key: barKey,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(barHeight / 2),
        boxShadow: AppTheme.floatingShadow(opacity: 0.14),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(barHeight / 2),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.86),
              borderRadius: BorderRadius.circular(barHeight / 2),
              border: Border.all(color: AppColors.line),
            ),
            child: SizedBox(
              height: barHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final count = entries.length;
                    final total = constraints.maxWidth;
                    // The active tab gets room for its label; the rest share
                    // what is left (never under the 48 dp touch target).
                    final roomForOthers = total - 48.0 * (count - 1);
                    // Size the active pill to its real label so it never
                    // clips: icon 22 + gap 8 + padding 28 + breathing room.
                    double wide = total / count;
                    if (anySelected && count > 1) {
                      final active = entries.firstWhere((e) => e.selected);
                      final painter = TextPainter(
                        text: TextSpan(
                          text: active.label,
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        maxLines: 1,
                        textDirection: Directionality.of(context),
                        textScaler: MediaQuery.textScalerOf(context),
                      )..layout();
                      final needed = 22 + 8 + 28 + 12 + painter.width;
                      wide = needed
                          .clamp(
                            48.0,
                            roomForOthers < 48 ? 48.0 : roomForOthers,
                          )
                          .toDouble();
                      painter.dispose();
                    }
                    final narrow = !anySelected || count <= 1
                        ? total / count
                        : (total - wide) / (count - 1);
                    return Row(
                      children: [
                        for (final entry in entries)
                          _BarButton(
                            item: entry.item,
                            label: entry.label,
                            selected: entry.selected,
                            badgeCount: entry.badge,
                            width: entry.selected ? wide : narrow,
                            onTap: entry.onTap,
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openMore(BuildContext context, AppLocalizations l10n) async {
    final selected = await showModalBottomSheet<NavItem>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      sheetAnimationStyle: const AnimationStyle(
        curve: AppMotion.drawer,
        duration: Duration(milliseconds: 380),
        reverseDuration: Duration(milliseconds: 240),
      ),
      builder: (sheetContext) {
        return _GlassMoreSheet(
          items: moreItems,
          l10n: l10n,
          badgeCounts: badgeCounts,
        );
      },
    );
    if (selected == null) return;
    onMoreSelected?.call(selected);
  }
}

/// One destination. Inactive: just the icon. Active: a navy pill that grows
/// to reveal the label while the neighbours shrink to make room.
class _BarButton extends StatelessWidget {
  const _BarButton({
    required this.item,
    required this.label,
    required this.selected,
    required this.width,
    required this.onTap,
    this.badgeCount = 0,
  });

  final NavItem item;
  final String label;
  final bool selected;
  final double width;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration = reduceMotion ? Duration.zero : AppMotion.standard;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: duration,
        curve: AppMotion.easeInOut,
        width: width,
        height: GlassBottomBar.barHeight,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(end: selected ? 1 : 0),
              duration: duration,
              curve: AppMotion.easeInOut,
              builder: (context, t, _) {
                final fg = Color.lerp(AppColors.inkMuted, AppColors.white, t)!;
                return Container(
                  height: 44,
                  constraints: BoxConstraints(maxWidth: width - 4),
                  padding: EdgeInsetsDirectional.symmetric(
                    horizontal: 10 + 4 * t,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.navy.withValues(alpha: t),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Badge(
                        isLabelVisible: badgeCount > 0,
                        backgroundColor: theme.colorScheme.error,
                        label: Text(badgeCount > 99 ? '99+' : '$badgeCount'),
                        child: _PopIcon(
                          icon: item.icon,
                          color: fg,
                          selected: selected,
                          duration: duration,
                        ),
                      ),
                      Flexible(
                        child: ClipRect(
                          child: Align(
                            widthFactor: t,
                            child: Opacity(
                              opacity: t,
                              child: Padding(
                                padding: const EdgeInsetsDirectional.only(
                                  start: 8,
                                ),
                                child: Text(
                                  label,
                                  maxLines: 1,
                                  softWrap: false,
                                  overflow: TextOverflow.fade,
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    color: AppColors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// Icon that gives a small pop when it becomes the active tab.
class _PopIcon extends StatelessWidget {
  const _PopIcon({
    required this.icon,
    required this.color,
    required this.selected,
    required this.duration,
  });

  final IconData icon;
  final Color color;
  final bool selected;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(selected),
      tween: Tween<double>(begin: selected ? 0.8 : 1, end: 1),
      duration: duration == Duration.zero
          ? Duration.zero
          : const Duration(milliseconds: 420),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Icon(icon, size: 22, color: color),
    );
  }
}

class _GlassMoreSheet extends StatelessWidget {
  const _GlassMoreSheet({
    required this.items,
    required this.l10n,
    required this.badgeCounts,
  });

  final List<NavItem> items;
  final AppLocalizations l10n;
  final Map<String, int> badgeCounts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.9),
            border: const Border(top: BorderSide(color: AppColors.line)),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.line,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final item in items)
                      ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        leading: Badge(
                          isLabelVisible: (badgeCounts[item.id] ?? 0) > 0,
                          backgroundColor: theme.colorScheme.error,
                          label: Text(
                            (badgeCounts[item.id] ?? 0) > 99
                                ? '99+'
                                : '${badgeCounts[item.id] ?? 0}',
                          ),
                          child: Icon(item.icon, color: AppColors.deepBlue),
                        ),
                        title: Text(
                          navLabel(l10n, item.labelKey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall,
                        ),
                        trailing: const Icon(
                          Icons.chevron_right,
                          color: AppColors.inkMuted,
                        ),
                        onTap: () => Navigator.of(context).pop(item),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
