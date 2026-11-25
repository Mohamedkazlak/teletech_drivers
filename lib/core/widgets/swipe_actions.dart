import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/core/theme/app_theme.dart';

/// Swipe a list row toward the end to edit it, toward the start for the
/// destructive action. The row springs back; the action (and any
/// confirmation it asks for) runs after. Leave a callback null to disable
/// that direction. Every action stays reachable from the row's menu too.
class SwipeActions extends StatelessWidget {
  const SwipeActions({
    required this.itemKey,
    required this.child,
    this.onEdit,
    this.editLabel,
    this.onDestructive,
    this.destructiveLabel,
    this.destructiveIcon = Icons.person_off_outlined,
    super.key,
  });

  final Key itemKey;
  final Widget child;
  final VoidCallback? onEdit;
  final String? editLabel;
  final VoidCallback? onDestructive;
  final String? destructiveLabel;
  final IconData destructiveIcon;

  @override
  Widget build(BuildContext context) {
    final DismissDirection direction;
    if (onEdit != null && onDestructive != null) {
      direction = DismissDirection.horizontal;
    } else if (onEdit != null) {
      direction = DismissDirection.startToEnd;
    } else if (onDestructive != null) {
      direction = DismissDirection.endToStart;
    } else {
      return child;
    }

    return Dismissible(
      key: itemKey,
      direction: direction,
      dismissThresholds: const {
        DismissDirection.startToEnd: 0.3,
        DismissDirection.endToStart: 0.3,
      },
      confirmDismiss: (dir) async {
        HapticFeedback.mediumImpact();
        final action = dir == DismissDirection.startToEnd
            ? onEdit
            : onDestructive;
        // Let the row spring back first, then run the action.
        if (action != null) Future<void>.microtask(action);
        return false;
      },
      background: _ActionBackground(
        alignment: AlignmentDirectional.centerStart,
        color: AppColors.paleBlue,
        foreground: AppColors.deepBlue,
        icon: Icons.edit_outlined,
        label: editLabel,
      ),
      secondaryBackground: _ActionBackground(
        alignment: AlignmentDirectional.centerEnd,
        color: AppColors.error.withValues(alpha: 0.1),
        foreground: AppColors.inkOn(AppColors.error),
        icon: destructiveIcon,
        label: destructiveLabel,
      ),
      child: child,
    );
  }
}

class _ActionBackground extends StatelessWidget {
  const _ActionBackground({
    required this.alignment,
    required this.color,
    required this.foreground,
    required this.icon,
    this.label,
  });

  final AlignmentDirectional alignment;
  final Color color;
  final Color foreground;
  final IconData icon;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final children = [
      Icon(icon, color: foreground, size: 22),
      if (label != null) ...[
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ];
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      alignment: alignment,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: alignment == AlignmentDirectional.centerEnd
            ? children.reversed.toList()
            : children,
      ),
    );
  }
}
