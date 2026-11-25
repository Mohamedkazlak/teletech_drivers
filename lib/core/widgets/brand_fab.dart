import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/core/theme/app_motion.dart';
import 'package:teletech_drivers/core/widgets/animation_helpers.dart';

/// Brand floating action button: gradient disc, coloured shadow, springs in
/// when the screen appears, presses down, and the icon tilts and settles back on tap.
class BrandFab extends StatefulWidget {
  const BrandFab({
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.heroTag,
    this.label,
    super.key,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Object? heroTag;

  /// Optional text; turns the button into an extended pill.
  final String? label;

  @override
  State<BrandFab> createState() => _BrandFabState();
}

class _BrandFabState extends State<BrandFab> with TickerProviderStateMixin {
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: AppMotion.emphasized,
  );
  var _pressed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppAnimations.disabled(context)) {
      _enter.value = 1;
    } else if (!_enter.isCompleted && !_enter.isAnimating) {
      _enter.forward();
    }
  }

  @override
  void dispose() {
    _enter.dispose();
    _spin.dispose();
    super.dispose();
  }

  void _tap() {
    final cb = widget.onPressed;
    if (cb == null) return;
    HapticFeedback.lightImpact();
    if (!AppAnimations.disabled(context)) _spin.forward(from: 0);
    cb();
  }

  @override
  Widget build(BuildContext context) {
    final extended = widget.label != null;
    final enabled = widget.onPressed != null;
    Widget fab = ScaleTransition(
      scale: CurvedAnimation(parent: _enter, curve: Curves.easeOutBack),
      child: AnimatedScale(
        scale: _pressed ? 0.93 : 1,
        duration: AppAnimations.duration(context, AppMotion.press),
        curve: AppMotion.easeOut,
        child: Container(
          height: 56,
          constraints: BoxConstraints(minWidth: extended ? 0 : 56),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(extended ? 28 : 18),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: AppColors.deepBlue.withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(extended ? 28 : 18),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: enabled
                      ? const [AppColors.signal, AppColors.deepBlue]
                      : const [AppColors.line, AppColors.line],
                ),
              ),
              child: InkWell(
              borderRadius: BorderRadius.circular(extended ? 28 : 18),
              onTap: enabled ? _tap : null,
              onHighlightChanged: (v) => setState(() => _pressed = v),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: extended ? 20 : 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RotationTransition(
                      // A quick tilt that returns to upright on its own.
                      turns: TweenSequence<double>([
                        TweenSequenceItem(
                          tween: Tween(begin: 0.0, end: 0.09),
                          weight: 1,
                        ),
                        TweenSequenceItem(
                          tween: Tween(begin: 0.09, end: 0.0),
                          weight: 1,
                        ),
                      ]).animate(
                        CurvedAnimation(parent: _spin, curve: AppMotion.easeOut),
                      ),
                      child: Icon(
                        widget.icon,
                        color: enabled ? AppColors.white : AppColors.inkMuted,
                        size: 26,
                      ),
                    ),
                    if (extended) ...[
                      const SizedBox(width: 10),
                      Text(
                        widget.label!,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            ),
          ),
        ),
      ),
    );
    if (widget.tooltip != null) {
      fab = Tooltip(message: widget.tooltip!, child: fab);
    }
    return Semantics(
      button: true,
      label: widget.tooltip ?? widget.label,
      excludeSemantics: true,
      onTap: enabled ? _tap : null,
      child: fab,
    );
  }
}
