import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/core/theme/app_motion.dart';
import 'package:teletech_drivers/core/widgets/animation_helpers.dart';

/// Greeting block for end-user home screens.
///
/// Sits on the page itself (no card) so the screen's one hero surface, the
/// status card below it, carries the weight.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    required this.greeting,
    this.chips = const [],
    super.key,
  });

  final String greeting;
  final List<Widget> chips;

  @override
  Widget build(BuildContext context) {
    Widget header = Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(20, 12, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(greeting, style: Theme.of(context).textTheme.headlineSmall),
          if (chips.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(spacing: 8, runSpacing: 8, children: chips),
          ],
        ],
      ),
    );

    if (!AppAnimations.disabled(context)) {
      header = header
          .animate()
          .fadeIn(duration: AppMotion.standard)
          .moveY(
            begin: 6,
            end: 0,
            duration: AppMotion.emphasized,
            curve: AppMotion.easeOut,
          );
    }
    return header;
  }
}

/// Quiet label pill under the greeting (role, branch).
class HomeHeaderChip extends StatelessWidget {
  const HomeHeaderChip({required this.label, this.icon, super.key});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(10, 5, 12, 5),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: AppColors.inkMuted),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.inkMuted,
            ),
          ),
        ],
      ),
    );
  }
}
