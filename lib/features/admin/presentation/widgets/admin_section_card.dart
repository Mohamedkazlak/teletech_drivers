import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/core/theme/app_gradients.dart';
import 'package:teletech_drivers/core/theme/app_motion.dart';
import 'package:teletech_drivers/core/theme/app_theme.dart';
import 'package:teletech_drivers/core/theme/app_typography.dart';
import 'package:teletech_drivers/core/widgets/animation_helpers.dart';
import 'package:teletech_drivers/core/widgets/brand_mark.dart';
import 'package:teletech_drivers/core/widgets/pressable_scale.dart';

/// Dashboard tile: icon, count, title, hint. Taps to a section.
///
/// [emphasized] renders the primary action tile on the navy hero surface.
class AdminSectionCard extends StatelessWidget {
  const AdminSectionCard({
    required this.title,
    required this.icon,
    required this.onTap,
    this.count,
    this.subtitle,
    this.emphasized = false,
    this.animateIndex,
    super.key,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final int? count;
  final String? subtitle;
  final bool emphasized;
  final int? animateIndex;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final ink = emphasized ? AppColors.white : AppColors.navy;
    final muted = emphasized
        ? AppColors.white.withValues(alpha: 0.7)
        : AppColors.inkMuted;
    final radius = BorderRadius.circular(AppTheme.cardRadius);

    final content = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: emphasized
                      ? AppColors.white.withValues(alpha: 0.14)
                      : AppColors.paleBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: emphasized ? AppColors.white : AppColors.deepBlue,
                ),
              ),
              const Spacer(),
              if (count != null)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: count!.toDouble()),
                  duration: AppAnimations.duration(
                    context,
                    const Duration(milliseconds: 600),
                  ),
                  curve: AppMotion.easeOut,
                  builder: (context, value, _) => Text(
                    value.round().toString(),
                    style: AppTypography.tabular(
                      textTheme.headlineMedium?.copyWith(color: ink),
                    ),
                  ),
                )
              else
                Icon(Icons.arrow_forward_rounded, color: muted),
            ],
          ),
          const Spacer(),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleMedium?.copyWith(color: ink),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(color: muted),
            ),
          ],
        ],
      ),
    );

    Widget card = Material(
      color: emphasized ? Colors.transparent : AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: emphasized
            ? BorderSide.none
            : const BorderSide(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: emphasized
            ? const BoxDecoration(gradient: AppGradients.primary)
            : null,
        child: InkWell(
          onTap: onTap,
          child: emphasized
              ? Stack(
                  children: [
                    const Positioned.fill(child: RingField(opacity: 0.08)),
                    content,
                  ],
                )
              : content,
        ),
      ),
    );

    card = PressableScale(scale: 0.97, child: card);

    final index = animateIndex;
    if (index == null || AppAnimations.disabled(context)) return card;
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
