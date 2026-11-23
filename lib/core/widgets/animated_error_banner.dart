import 'package:flutter/material.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/core/widgets/animation_helpers.dart';

/// Sliding/fading inline error banner for forms.
class AnimatedErrorBanner extends StatelessWidget {
  const AnimatedErrorBanner({this.message, super.key});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final visible = message != null && message!.isNotEmpty;
    final duration = AppAnimations.duration(
      context,
      const Duration(milliseconds: 280),
    );

    return AnimatedSize(
      duration: duration,
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: visible
          ? TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: duration,
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, (1 - value) * -12),
                    child: child,
                  ),
                );
              },
              child: _BannerBody(message: message!),
            )
          : const SizedBox(width: double.infinity),
    );
  }
}

class _BannerBody extends StatelessWidget {
  const _BannerBody({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.error.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.error,
                ),
                textAlign: TextAlign.start,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
