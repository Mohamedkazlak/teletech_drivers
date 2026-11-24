import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/core/theme/app_theme.dart';
import 'package:teletech_drivers/core/widgets/animation_helpers.dart';

/// Progress indicator with a localized semantics label.
class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: SizedBox.square(
          dimension: 28,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            strokeCap: StrokeCap.round,
            backgroundColor: AppColors.paleBlue,
          ),
        ),
      ),
    );
  }
}

/// A rounded placeholder block that shimmers while content loads.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    this.width,
    this.height = 14,
    this.radius = 8,
    super.key,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.paleBlue,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Card-shaped loading placeholders for trip lists. One shimmer sweeps the
/// whole list so the blocks read as one surface, not many spinners.
class TripListSkeleton extends StatelessWidget {
  const TripListSkeleton({required this.label, this.count = 3, super.key});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    Widget list = Column(
      children: [
        for (var i = 0; i < count; i++) ...[
          const _SkeletonCard(),
          if (i < count - 1) const SizedBox(height: 12),
        ],
      ],
    );

    if (!AppAnimations.disabled(context)) {
      list = list
          .animate(onPlay: (controller) => controller.repeat())
          .shimmer(
            duration: const Duration(milliseconds: 1400),
            color: AppColors.white.withValues(alpha: 0.7),
          );
    }

    return Semantics(
      label: label,
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 16),
        child: ExcludeSemantics(child: list),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppColors.line),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SkeletonBox(width: 84, height: 22, radius: 11),
              Spacer(),
              SkeletonBox(width: 64),
            ],
          ),
          SizedBox(height: 16),
          SkeletonBox(width: 140),
          SizedBox(height: 10),
          SkeletonBox(width: 200, height: 18),
          SizedBox(height: 16),
          SkeletonBox(height: 12),
        ],
      ),
    );
  }
}
