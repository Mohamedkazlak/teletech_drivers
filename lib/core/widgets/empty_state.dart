import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/core/theme/app_motion.dart';
import 'package:teletech_drivers/core/widgets/animation_helpers.dart';
import 'package:teletech_drivers/core/widgets/route_line.dart';

/// Empty-list placeholder. Trip lists use the self-drawing route sketch;
/// everything else a quiet icon on a pale ring.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.illustration,
    this.action,
    super.key,
  });

  final String title;
  final String message;
  final IconData icon;

  /// Replaces the icon (e.g. [RouteSketch] for trip lists).
  final Widget? illustration;

  /// Optional next step, shown under the message.
  final Widget? action;

  /// Empty state for trip lists: the route draws itself.
  const EmptyState.route({
    required this.title,
    required this.message,
    this.action,
    super.key,
  }) : icon = Icons.route_outlined,
       illustration = const RouteSketch();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    final art =
        illustration ??
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.white,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.line),
          ),
          child: Icon(icon, size: 30, color: AppColors.deepBlue),
        );

    Widget content = Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: 32,
        vertical: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          art,
          const SizedBox(height: 20),
          Text(
            title,
            style: textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Text(
              message,
              style: textTheme.bodyMedium?.copyWith(color: AppColors.inkMuted),
              textAlign: TextAlign.center,
            ),
          ),
          if (action != null) ...[const SizedBox(height: 20), action!],
        ],
      ),
    );

    if (!AppAnimations.disabled(context)) {
      content = content
          .animate()
          .fadeIn(duration: AppMotion.standard, curve: AppMotion.easeOut)
          .moveY(
            begin: 8,
            end: 0,
            duration: AppMotion.standard,
            curve: AppMotion.easeOut,
          );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.maxHeight.isFinite) return content;
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: constraints.maxWidth),
            child: content,
          ),
        );
      },
    );
  }
}
