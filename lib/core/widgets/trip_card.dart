import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/core/theme/app_motion.dart';
import 'package:teletech_drivers/core/theme/app_theme.dart';
import 'package:teletech_drivers/core/theme/app_typography.dart';
import 'package:teletech_drivers/core/widgets/animation_helpers.dart';
import 'package:teletech_drivers/core/widgets/pressable_scale.dart';
import 'package:teletech_drivers/core/widgets/route_line.dart';
import 'package:teletech_drivers/core/widgets/status_chip.dart';

/// Shared trip / request summary card.
///
/// Status chip and [meta] (time) on top; then either the route ([from] → [to])
/// or a plain [title]. Hairline border, no side bar, scales on press.
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
    this.from,
    this.to,
    this.meta,
    this.live = false,
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

  /// Pickup and destination. When both are set the route replaces [title].
  final String? from;
  final String? to;

  /// Short text on the top row's end (e.g. the scheduled time).
  final String? meta;

  /// Trip in progress: the route line turns to the live colour.
  final bool live;

  static const _entranceCap = 8;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasRoute = from != null && to != null;
    final radius = BorderRadius.circular(AppTheme.cardRadius);

    final body = Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Flexible(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: StatusChip(label: statusLabel, color: statusColor),
                ),
              ),
              if (meta != null) ...[
                const SizedBox(width: 12),
                Text(
                  meta!,
                  style: AppTypography.tabular(
                    textTheme.labelMedium?.copyWith(color: AppColors.inkMuted),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          if (hasRoute)
            RouteLine(from: from!, to: to!, live: live)
          else
            Row(
              children: [
                Icon(leadingIcon, color: AppColors.deepBlue, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(title, style: textTheme.titleMedium)),
              ],
            ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              subtitle!,
              style: textTheme.bodyMedium?.copyWith(color: AppColors.inkMuted),
            ),
          ],
          if (trailing != null) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            DefaultTextStyle.merge(
              style: TextStyle(color: AppColors.inkMuted),
              child: trailing!,
            ),
          ],
          if (footer != null) ...[const SizedBox(height: 16), footer!],
        ],
      ),
    );

    Widget card = Material(
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(
          color: live
              ? AppColors.signal.withValues(alpha: 0.45)
              : AppColors.line,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: body),
    );

    if (onTap != null) {
      card = PressableScale(scale: 0.985, child: card);
    }

    final index = animateIndex;
    if (index == null ||
        index >= _entranceCap ||
        AppAnimations.disabled(context)) {
      return card;
    }

    final delay = AppMotion.staggerAt(index);
    return card
        .animate()
        .fadeIn(delay: delay, duration: AppMotion.standard)
        .moveY(
          begin: 12,
          end: 0,
          delay: delay,
          duration: AppMotion.emphasized,
          curve: AppMotion.easeOut,
        );
  }
}
