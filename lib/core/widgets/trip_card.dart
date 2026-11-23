import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/core/theme/app_theme.dart';
import 'package:teletech_drivers/core/widgets/animation_helpers.dart';
import 'package:teletech_drivers/core/widgets/status_chip.dart';

/// Shared trip / request summary card with status accent.
class TripCard extends StatelessWidget {
  const TripCard({
    required this.title,
    required this.statusLabel,
    required this.statusColor,
    this.subtitle,
    this.trailing,
    this.footer,
    this.onTap,
    this.leadingIcon = Icons.route_outlined,
    this.animateIndex,
    super.key,
  });

  final String title;
  final String statusLabel;
  final Color statusColor;
  final String? subtitle;
  final Widget? trailing;
  final Widget? footer;
  final VoidCallback? onTap;
  final IconData leadingIcon;
  final int? animateIndex;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    Widget card = Material(
      color: AppColors.white,
      elevation: 0,
      shadowColor: AppColors.deepBlue.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            boxShadow: [
              BoxShadow(
                color: AppColors.deepBlue.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          // Stack (not IntrinsicHeight) so nested scrollables never get an
          // intrinsic-size query that ShrinkWrappingViewport cannot answer.
          child: Stack(
            children: [
              PositionedDirectional(
                start: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 5,
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: const BorderRadiusDirectional.only(
                      topStart: Radius.circular(AppTheme.cardRadius),
                      bottomStart: Radius.circular(AppTheme.cardRadius),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(19, 14, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(leadingIcon, color: statusColor, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(title, style: textTheme.titleMedium),
                        ),
                        const SizedBox(width: 8),
                        StatusChip(label: statusLabel, color: statusColor),
                      ],
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(subtitle!, style: textTheme.bodyMedium),
                    ],
                    if (trailing != null) ...[
                      const SizedBox(height: 8),
                      trailing!,
                    ],
                    if (footer != null) ...[
                      const SizedBox(height: 12),
                      footer!,
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final index = animateIndex;
    if (index == null || AppAnimations.disabled(context)) {
      return card;
    }

    return card
        .animate()
        .fadeIn(delay: AppAnimations.stagger(context, index), duration: 320.ms)
        .slideY(
          begin: 0.08,
          end: 0,
          delay: AppAnimations.stagger(context, index),
          duration: 320.ms,
          curve: Curves.easeOutCubic,
        );
  }
}
