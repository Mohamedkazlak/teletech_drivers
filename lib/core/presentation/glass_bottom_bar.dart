import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/navigation/nav_ids.dart';
import 'package:teletech_drivers/core/navigation/nav_item.dart';
import 'package:teletech_drivers/core/navigation/nav_label_key.dart';
import 'package:teletech_drivers/core/navigation/nav_labels.dart';

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = theme.colorScheme.surface;
    final fill = surface.withValues(alpha: isDark ? 0.45 : 0.55);
    final borderColor = theme.colorScheme.outline.withValues(alpha: 0.35);
    final showMore = moreItems.isNotEmpty;

    return DecoratedBox(
      key: barKey,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.16),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: borderColor),
            ),
            child: SizedBox(
              height: barHeight,
              child: Row(
                children: [
                  for (var index = 0; index < items.length; index++)
                    Expanded(
                      child: _BarButton(
                        item: items[index],
                        label: navLabel(l10n, items[index].labelKey),
                        selected: index == selectedIndex,
                        badgeCount: badgeCounts[items[index].id] ?? 0,
                        onTap: () => onSelected(index),
                      ),
                    ),
                  if (showMore)
                    Expanded(
                      child: _BarButton(
                        item: const NavItem(
                          id: NavIds.more,
                          icon: Icons.more_horiz,
                          labelKey: NavLabelKey.more,
                          route: '',
                        ),
                        label: navLabel(l10n, NavLabelKey.more),
                        selected: moreSelected,
                        onTap: () => _openMore(context, l10n),
                      ),
                    ),
                ],
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

class _BarButton extends StatelessWidget {
  const _BarButton({
    required this.item,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badgeCount = 0,
  });

  final NavItem item;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final color = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: AnimatedContainer(
            duration: disableAnimations
                ? Duration.zero
                : const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: selected
                  ? theme.colorScheme.primary.withValues(alpha: 0.16)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Badge(
                  isLabelVisible: badgeCount > 0,
                  backgroundColor: theme.colorScheme.error,
                  label: Text(badgeCount > 99 ? '99+' : '$badgeCount'),
                  child: Icon(item.icon, size: 22, color: color),
                ),
                const SizedBox(height: 2),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: color,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
    final isDark = theme.brightness == Brightness.dark;
    final fill = theme.colorScheme.surface.withValues(
      alpha: isDark ? 0.45 : 0.55,
    );

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: fill,
            border: Border(
              top: BorderSide(
                color: theme.colorScheme.outline.withValues(alpha: 0.35),
              ),
            ),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  for (final item in items)
                    ListTile(
                      leading: Badge(
                        isLabelVisible: (badgeCounts[item.id] ?? 0) > 0,
                        backgroundColor: theme.colorScheme.error,
                        label: Text(
                          (badgeCounts[item.id] ?? 0) > 99
                              ? '99+'
                              : '${badgeCounts[item.id] ?? 0}',
                        ),
                        child: Icon(item.icon),
                      ),
                      title: Text(
                        navLabel(l10n, item.labelKey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => Navigator.of(context).pop(item),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
