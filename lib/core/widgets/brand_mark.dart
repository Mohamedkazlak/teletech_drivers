import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/core/theme/app_motion.dart';
import 'package:teletech_drivers/core/widgets/animation_helpers.dart';

/// The TeleTech ring mark (◎) as a crisp vector: a blue disc with two white
/// concentric rings. Replaces the low-resolution logo raster in app bars.
class BrandMark extends StatelessWidget {
  const BrandMark({this.size = 28, this.color = AppColors.deepBlue, super.key});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'TeleCars',
      image: true,
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _MarkPainter(color)),
      ),
    );
  }
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Proportions taken from the vector logo (disc r 47, rings r 34 / 24).
    final r = size.shortestSide / 2;
    final c = size.center(Offset.zero);
    canvas.drawCircle(c, r, Paint()..color = color);
    final ring = Paint()
      ..color = AppColors.white
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(
      c.translate(r * 0.04, 0),
      r * 34 / 47,
      ring..strokeWidth = r * 5 / 47 * 1.4,
    );
    canvas.drawCircle(
      c.translate(r * 0.085, r * 0.01),
      r * 24 / 47,
      ring..strokeWidth = r * 3 / 47 * 1.5,
    );
  }

  @override
  bool shouldRepaint(_MarkPainter oldDelegate) => oldDelegate.color != color;
}

/// Static field of concentric rings: the decorative ground of hero surfaces.
class RingField extends StatelessWidget {
  const RingField({
    this.color = AppColors.white,
    this.opacity = 0.07,
    this.rings = 5,
    super.key,
  });

  final Color color;
  final double opacity;
  final int rings;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _RingFieldPainter(
          color: color.withValues(alpha: opacity),
          rings: rings,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _RingFieldPainter extends CustomPainter {
  const _RingFieldPainter({required this.color, required this.rings});

  final Color color;
  final int rings;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final center = Offset(size.width * 0.92, size.height * 0.1);
    final step = math.max(size.width, size.height) / (rings + 1);
    for (var i = 1; i <= rings; i++) {
      canvas.drawCircle(center, step * i, paint);
    }
  }

  @override
  bool shouldRepaint(_RingFieldPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.rings != rings;
  }
}

/// Live signal: rings that slowly expand and fade from the centre.
///
/// Used while something is live (checked in, trip in progress). Under
/// "Remove animations" it renders one still ring.
class RingPulse extends StatefulWidget {
  const RingPulse({
    required this.size,
    this.color = AppColors.signal,
    this.active = true,
    this.period = const Duration(milliseconds: 2400),
    this.child,
    super.key,
  });

  final double size;
  final Color color;
  final bool active;
  final Duration period;
  final Widget? child;

  @override
  State<RingPulse> createState() => _RingPulseState();
}

class _RingPulseState extends State<RingPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.period,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(RingPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final run = widget.active && !AppAnimations.disabled(context);
    if (run && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!run && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.active)
            Positioned.fill(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) => CustomPaint(
                    painter: _PulsePainter(
                      t: _controller.value,
                      color: widget.color,
                      animating: _controller.isAnimating,
                    ),
                  ),
                ),
              ),
            ),
          if (widget.child != null) widget.child!,
        ],
      ),
    );
  }
}

class _PulsePainter extends CustomPainter {
  const _PulsePainter({
    required this.t,
    required this.color,
    required this.animating,
  });

  final double t;
  final Color color;
  final bool animating;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final maxR = size.shortestSide / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    if (!animating) {
      paint.color = color.withValues(alpha: 0.35);
      canvas.drawCircle(c, maxR * 0.78, paint);
      return;
    }
    // Two rings, half a period apart.
    for (final offset in const [0.0, 0.5]) {
      final p = (t + offset) % 1.0;
      final eased = AppMotion.easeOut.transform(p);
      final radius = maxR * (0.5 + 0.5 * eased);
      paint.color = color.withValues(alpha: 0.45 * (1 - p));
      canvas.drawCircle(c, radius, paint);
    }
  }

  @override
  bool shouldRepaint(_PulsePainter oldDelegate) {
    return oldDelegate.t != t ||
        oldDelegate.color != color ||
        oldDelegate.animating != animating;
  }
}

/// One-shot ring burst, replayed whenever [trigger] changes.
///
/// The check-in moment: three rings ripple out once from the status mark.
class RingBurst extends StatefulWidget {
  const RingBurst({
    required this.trigger,
    required this.child,
    this.color = AppColors.signal,
    this.spread = 2.4,
    super.key,
  });

  /// Any value; a change replays the burst. Null never plays.
  final Object? trigger;
  final Widget child;
  final Color color;

  /// How far the rings travel, as a multiple of the child's size.
  final double spread;

  @override
  State<RingBurst> createState() => _RingBurstState();
}

class _RingBurstState extends State<RingBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didUpdateWidget(RingBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != null &&
        widget.trigger != oldWidget.trigger &&
        !AppAnimations.disabled(context)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                if (!_controller.isAnimating) return const SizedBox.shrink();
                return CustomPaint(
                  painter: _BurstPainter(
                    t: _controller.value,
                    color: widget.color,
                    spread: widget.spread,
                  ),
                );
              },
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _BurstPainter extends CustomPainter {
  const _BurstPainter({
    required this.t,
    required this.color,
    required this.spread,
  });

  final double t;
  final Color color;
  final double spread;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final base = size.shortestSide / 2;
    final paint = Paint()..style = PaintingStyle.stroke;
    for (var i = 0; i < 3; i++) {
      final start = i * 0.12;
      final local = ((t - start) / (1 - start)).clamp(0.0, 1.0);
      if (local <= 0) continue;
      final eased = AppMotion.easeOut.transform(local);
      paint
        ..strokeWidth = 2.5 * (1 - local) + 0.5
        ..color = color.withValues(alpha: 0.6 * (1 - local));
      canvas.drawCircle(c, base * (1 + (spread - 1) * eased), paint);
    }
  }

  @override
  bool shouldRepaint(_BurstPainter oldDelegate) => oldDelegate.t != t;
}
