import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/core/theme/app_motion.dart';
import 'package:teletech_drivers/core/theme/app_theme.dart';
import 'package:teletech_drivers/core/widgets/animation_helpers.dart';

/// White content card with the hairline border (see DESIGN.md → depth).
///
/// Wrap list rows (ListTile etc.) in it instead of divider-separated rows.
/// [animateIndex] staggers it in with its siblings on first build.
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    required this.child,
    this.padding = EdgeInsets.zero,
    this.animateIndex,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final int? animateIndex;

  @override
  Widget build(BuildContext context) {
    Widget card = Material(
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        side: const BorderSide(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: padding, child: child),
    );

    final index = animateIndex;
    if (index == null || index >= 8 || AppAnimations.disabled(context)) {
      return card;
    }
    final delay = AppMotion.staggerAt(index);
    return card
        .animate()
        .fadeIn(delay: delay, duration: AppMotion.standard)
        .moveY(
          begin: 10,
          end: 0,
          delay: delay,
          duration: AppMotion.emphasized,
          curve: AppMotion.easeOut,
        );
  }
}

/// Initials in a tinted circle, with an optional status dot.
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({
    required this.name,
    this.size = 44,
    this.statusColor,
    super.key,
  });

  final String name;
  final double size;
  final Color? statusColor;

  String get _initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    final first = parts.first.characters.first;
    final last = parts.length > 1 ? parts.last.characters.first : '';
    return (first + last).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.paleBlue,
              shape: BoxShape.circle,
            ),
            child: Text(
              _initials,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.deepBlue,
              ),
            ),
          ),
          if (statusColor != null)
            PositionedDirectional(
              end: 0,
              bottom: 0,
              child: Container(
                width: size * 0.28,
                height: size * 0.28,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
