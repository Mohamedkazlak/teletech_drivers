import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/core/theme/app_motion.dart';
import 'package:teletech_drivers/core/theme/app_theme.dart';
import 'package:teletech_drivers/core/widgets/animation_helpers.dart';

enum AppButtonVariant { filled, outlined, danger, tonal }

/// Full-width friendly primary action.
///
/// Filled buttons carry a gradient with a soft coloured shadow, a light sweep
/// on press, a press-down scale with a haptic tick, and a label that morphs
/// into a spinner while loading. Set [pulse] to draw the eye to the single
/// next step on a screen (a slow glow, never more than one per screen).
class AppButton extends StatefulWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.loadingLabel,
    this.variant = AppButtonVariant.filled,
    this.icon,
    this.trailingIcon,
    this.pulse = false,
    this.onDark = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final String? loadingLabel;
  final AppButtonVariant variant;

  /// Leading icon.
  final IconData? icon;

  /// Trailing icon; nudges forward on press (flips in RTL).
  final IconData? trailingIcon;

  /// Slow attention glow behind a filled button.
  final bool pulse;

  /// Light button for use on the dark hero surface.
  final bool onDark;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> with TickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620),
  );
  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );
  var _pressed = false;

  bool get _enabled => widget.onPressed != null && !widget.isLoading;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncGlow();
  }

  @override
  void didUpdateWidget(AppButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncGlow();
  }

  void _syncGlow() {
    final run = widget.pulse &&
        _enabled &&
        widget.variant == AppButtonVariant.filled &&
        !AppAnimations.disabled(context);
    if (run && !_glow.isAnimating) {
      _glow.repeat(reverse: true);
    } else if (!run && _glow.isAnimating) {
      _glow
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _sweep.dispose();
    _glow.dispose();
    super.dispose();
  }

  void _setPressed(bool value) {
    if (!_enabled || _pressed == value) return;
    if (value) {
      if (widget.variant == AppButtonVariant.filled) {
        HapticFeedback.lightImpact();
      }
      if (!AppAnimations.disabled(context)) _sweep.forward(from: 0);
    }
    setState(() => _pressed = value);
  }

  ({Color fg, Color? bg, Gradient? gradient, BorderSide? border}) _look() {
    final enabled = _enabled || widget.isLoading;
    if (!enabled) {
      return (
        fg: AppColors.inkMuted,
        bg: AppColors.line,
        gradient: null,
        border: null,
      );
    }
    return switch (widget.variant) {
      AppButtonVariant.filled when widget.onDark => (
        fg: AppColors.navy,
        bg: AppColors.white,
        gradient: null,
        border: null,
      ),
      AppButtonVariant.filled => (
        fg: AppColors.white,
        bg: null,
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1560C4), AppColors.deepBlue],
        ),
        border: null,
      ),
      AppButtonVariant.outlined => (
        fg: widget.onDark ? AppColors.white : AppColors.deepBlue,
        bg: widget.onDark ? Colors.white.withValues(alpha: 0.08) : AppColors.white,
        gradient: null,
        border: BorderSide(
          color: widget.onDark
              ? Colors.white.withValues(alpha: 0.35)
              : AppColors.line,
          width: 1.2,
        ),
      ),
      AppButtonVariant.tonal => (
        fg: AppColors.deepBlue,
        bg: AppColors.paleBlue,
        gradient: null,
        border: null,
      ),
      AppButtonVariant.danger => (
        fg: AppColors.inkOn(AppColors.error),
        bg: AppColors.error.withValues(alpha: 0.1),
        gradient: null,
        border: null,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final look = _look();
    final filled = widget.variant == AppButtonVariant.filled &&
        _enabled &&
        !widget.onDark;
    final reduced = AppAnimations.disabled(context);
    final radius = BorderRadius.circular(AppTheme.controlRadius);
    final textStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
      color: look.fg,
      fontWeight: FontWeight.w600,
    );

    final content = AnimatedSwitcher(
      duration: AppMotion.quick,
      reverseDuration: AppMotion.exit,
      switchInCurve: AppMotion.easeOut,
      switchOutCurve: AppMotion.easeOut,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.9, end: 1).animate(animation),
          child: child,
        ),
      ),
      child: widget.isLoading
          ? SizedBox.square(
              key: const ValueKey('loading'),
              dimension: 22,
              child: Semantics(
                label: widget.loadingLabel ?? widget.label,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: widget.variant == AppButtonVariant.filled &&
                          !widget.onDark
                      ? AppColors.white
                      : look.fg,
                ),
              ),
            )
          : Row(
              key: ValueKey(widget.label),
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 20, color: look.fg),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textStyle,
                  ),
                ),
                if (widget.trailingIcon != null) ...[
                  const SizedBox(width: 8),
                  AnimatedSlide(
                    duration: AppAnimations.duration(context, AppMotion.quick),
                    curve: AppMotion.easeOut,
                    offset: _pressed ? const Offset(0.25, 0) : Offset.zero,
                    child: Icon(widget.trailingIcon, size: 20, color: look.fg),
                  ),
                ],
              ],
            ),
    );

    final surface = AnimatedBuilder(
      animation: Listenable.merge([_sweep, _glow]),
      builder: (context, child) {
        final glow = Curves.easeInOut.transform(_glow.value);
        return Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: [
              if (filled)
                BoxShadow(
                  color: AppColors.deepBlue.withValues(
                    alpha: (_pressed ? 0.16 : 0.28) + glow * 0.16,
                  ),
                  blurRadius: _pressed ? 8 : 16 + glow * 10,
                  offset: Offset(0, _pressed ? 2 : 6),
                  spreadRadius: glow * 1.5,
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: Stack(
              children: [
                child!,
                if (filled && _sweep.isAnimating)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: FractionallySizedBox(
                        alignment: Alignment(-1.6 + _sweep.value * 3.4, 0),
                        widthFactor: 0.35,
                        child: Transform(
                          transform: Matrix4.skewX(-0.35),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0),
                                  Colors.white.withValues(alpha: 0.22),
                                  Colors.white.withValues(alpha: 0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
      child: Material(
        type: MaterialType.transparency,
        child: Ink(
          decoration: BoxDecoration(
            color: look.bg,
            gradient: look.gradient,
            borderRadius: radius,
            border: look.border == null
                ? null
                : Border.fromBorderSide(look.border!),
          ),
          child: InkWell(
            borderRadius: radius,
            onTap: _enabled ? widget.onPressed : null,
            splashColor: look.fg.withValues(alpha: 0.10),
            highlightColor: look.fg.withValues(alpha: 0.05),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: AppTheme.controlHeight,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Center(child: content),
              ),
            ),
          ),
        ),
      ),
    );

    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed && !reduced ? 0.97 : 1,
        duration: AppAnimations.duration(
          context,
          _pressed ? AppMotion.press : AppMotion.quick,
        ),
        curve: AppMotion.easeOut,
        child: Semantics(
          button: true,
          enabled: _enabled,
          label: widget.label,
          excludeSemantics: true,
          onTap: _enabled ? widget.onPressed : null,
          child: surface,
        ),
      ),
    );
  }
}
