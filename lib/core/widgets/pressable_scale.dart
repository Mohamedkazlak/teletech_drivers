import 'package:flutter/material.dart';
import 'package:teletech_drivers/core/widgets/animation_helpers.dart';

/// Scales slightly on press without blocking interaction.
class PressableScale extends StatefulWidget {
  const PressableScale({
    required this.child,
    this.onTap,
    this.enabled = true,
    this.scale = 0.97,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool enabled;
  final double scale;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  var _pressed = false;

  void _setPressed(bool value) {
    if (!widget.enabled || AppAnimations.disabled(context)) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final duration = AppAnimations.duration(
      context,
      const Duration(milliseconds: 120),
    );

    Widget child = AnimatedScale(
      scale: _pressed ? widget.scale : 1,
      duration: duration,
      curve: Curves.easeOut,
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
