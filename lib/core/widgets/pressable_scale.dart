import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:teletech_drivers/core/theme/app_motion.dart';
import 'package:teletech_drivers/core/widgets/animation_helpers.dart';

/// Scales slightly on press without blocking interaction.
class PressableScale extends StatefulWidget {
  const PressableScale({
    required this.child,
    this.onTap,
    this.enabled = true,
    this.scale = 0.97,
    this.haptic = false,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;
  final double scale;

  /// Light haptic tick on press-down (primary actions).
  final bool haptic;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  var _pressed = false;

  void _setPressed(bool value) {
    if (!widget.enabled) return;
    if (value && widget.haptic) HapticFeedback.lightImpact();
    if (AppAnimations.disabled(context)) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    // Press is quick; release is a touch slower so the rebound reads.
    final duration = AppAnimations.duration(
      context,
      _pressed ? AppMotion.press : AppMotion.quick,
    );

    Widget child = AnimatedScale(
      scale: _pressed ? widget.scale : 1,
      duration: duration,
      curve: AppMotion.easeOut,
      child: widget.child,
    );

    child = Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: child,
    );

    final onTap = widget.onTap;
    if (onTap == null) return child;

    return GestureDetector(
      behavior: HitTestBehavior.deferToChild,
      onTap: widget.enabled ? onTap : null,
      child: child,
    );
  }
}
