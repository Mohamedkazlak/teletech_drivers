import 'package:flutter/material.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/core/theme/app_motion.dart';
import 'package:teletech_drivers/core/theme/app_theme.dart';
import 'package:teletech_drivers/core/widgets/pressable_scale.dart';

enum AppButtonVariant { filled, outlined, danger }

/// Full-width friendly primary action with loading transition.
class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.loadingLabel,
    this.variant = AppButtonVariant.filled,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final String? loadingLabel;
  final AppButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    final child = AnimatedSwitcher(
      duration: AppMotion.quick,
      reverseDuration: AppMotion.exit,
      switchInCurve: AppMotion.easeOut,
      switchOutCurve: AppMotion.easeOut,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1).animate(animation),
          child: child,
        ),
      ),
      child: isLoading
          ? SizedBox.square(
              key: const ValueKey('loading'),
              dimension: 22,
              child: Semantics(
                label: loadingLabel ?? label,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: switch (variant) {
                    AppButtonVariant.filled => AppColors.white,
                    AppButtonVariant.outlined => AppColors.deepBlue,
                    AppButtonVariant.danger => AppColors.error,
                  },
                ),
              ),
            )
          : Text(key: ValueKey(label), label),
    );

    const fullWidth = Size.fromHeight(AppTheme.controlHeight);
    final button = switch (variant) {
      AppButtonVariant.filled => FilledButton(
        style: FilledButton.styleFrom(minimumSize: fullWidth),
        onPressed: enabled ? onPressed : null,
        child: child,
      ),
      AppButtonVariant.outlined => OutlinedButton(
        style: OutlinedButton.styleFrom(minimumSize: fullWidth),
        onPressed: enabled ? onPressed : null,
        child: child,
      ),
      AppButtonVariant.danger => FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.error.withValues(alpha: 0.1),
          foregroundColor: AppColors.inkOn(AppColors.error),
          disabledBackgroundColor: AppColors.error.withValues(alpha: 0.06),
          shadowColor: Colors.transparent,
          elevation: 0,
          minimumSize: fullWidth,
        ),
        onPressed: enabled ? onPressed : null,
        child: child,
      ),
    };

    return PressableScale(
      enabled: enabled,
      haptic: variant == AppButtonVariant.filled,
      child: button,
    );
  }
}
