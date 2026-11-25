import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:teletech_drivers/core/widgets/animation_helpers.dart';

/// Shakes [child] sideways each time [trigger] changes, with a light buzz.
///
/// Use for "that didn't work" moments: wrong password, invalid form.
class Shake extends StatefulWidget {
  const Shake({
    required this.trigger,
    required this.child,
    this.distance = 8,
    this.haptic = true,
    super.key,
  });

  final int trigger;
  final Widget child;
  final double distance;
  final bool haptic;

  @override
  State<Shake> createState() => _ShakeState();
}

class _ShakeState extends State<Shake> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void didUpdateWidget(Shake oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != oldWidget.trigger) {
      if (widget.haptic) HapticFeedback.mediumImpact();
      if (!AppAnimations.disabled(context)) _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        final t = _controller.value;
        // Three decaying swings.
        final dx = math.sin(t * math.pi * 6) * widget.distance * (1 - t);
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
    );
  }
}
