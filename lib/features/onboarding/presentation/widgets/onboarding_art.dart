import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/core/theme/app_motion.dart';
import 'package:teletech_drivers/core/widgets/animation_helpers.dart';
import 'package:teletech_drivers/core/widgets/brand_mark.dart';

/// Animated illustration for one onboarding step: pulsing rings, a centre disc
/// and three icons orbiting it. Everything flies out from the centre the
/// moment the step becomes [active], then idles. Static under reduced motion.
class OnboardingArt extends StatefulWidget {
  const OnboardingArt({
    required this.icon,
    required this.satellites,
    required this.active,
    this.useBrandMark = false,
    super.key,
  });

  final IconData icon;
  final List<IconData> satellites;
  final bool active;

  /// Shows the ring logo in the disc instead of [icon] (welcome page).
  final bool useBrandMark;

  @override
  State<OnboardingArt> createState() => _OnboardingArtState();
}

class _OnboardingArtState extends State<OnboardingArt>
    with TickerProviderStateMixin {
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 18),
  );

  var _started = false;

  // MediaQuery can't be read in initState, so the first reveal starts here.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      if (widget.active) _enter();
    }
    if (AppAnimations.disabled(context)) {
      _reveal.value = widget.active ? 1 : 0;
      _idle.stop();
    }
  }

  @override
  void didUpdateWidget(OnboardingArt oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _enter();
    } else if (!widget.active && oldWidget.active) {
      _idle.stop();
      _reveal.value = 0;
    }
  }

  void _enter() {
    if (AppAnimations.disabled(context)) {
      _reveal.value = 1;
      return;
    }
    _reveal.forward(from: 0);
    _idle.repeat();
  }

  @override
  void dispose() {
    _reveal.dispose();
    _idle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, box) {
          final side = box.biggest.shortestSide;
          return AnimatedBuilder(
            animation: Listenable.merge([_reveal, _idle]),
            builder: (context, _) {
              final enter = AppMotion.easeOut.transform(_reveal.value);
              final spring = Curves.easeOutBack.transform(
                _reveal.value.clamp(0.0, 1.0),
              );
              final t = _idle.value;
              final orbit = side * 0.40;
              final disc = side * 0.38;
              return Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: Size.square(side),
                    painter: _RingsPainter(
                      progress: t,
                      reveal: enter,
                      animate: !AppAnimations.disabled(context),
                    ),
                  ),
                  for (var i = 0; i < widget.satellites.length; i++)
                    _Satellite(
                      icon: widget.satellites[i],
                      angle:
                          -math.pi / 2 +
                          i * 2 * math.pi / widget.satellites.length +
                          t * 2 * math.pi,
                      radius: orbit * enter,
                      bob: math.sin((t * 4 + i / 3) * 2 * math.pi) * 4,
                      opacity: enter.clamp(0.0, 1.0),
                      size: side * 0.17,
                    ),
                  Transform.scale(
                    scale: 0.4 + 0.6 * spring,
                    child: Opacity(
                      opacity: enter.clamp(0.0, 1.0),
                      child: Container(
                        width: disc,
                        height: disc,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.white,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.signal.withValues(alpha: 0.55),
                              blurRadius: 38,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: widget.useBrandMark
                              ? BrandMark(size: disc * 0.62)
                              : Icon(
                                  widget.icon,
                                  size: disc * 0.48,
                                  color: AppColors.deepBlue,
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _Satellite extends StatelessWidget {
  const _Satellite({
    required this.icon,
    required this.angle,
    required this.radius,
    required this.bob,
    required this.opacity,
    required this.size,
  });

  final IconData icon;
  final double angle;
  final double radius;
  final double bob;
  final double opacity;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(math.cos(angle) * radius, math.sin(angle) * radius + bob),
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.32),
            color: Colors.white.withValues(alpha: 0.14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
          ),
          child: Icon(icon, color: AppColors.white, size: size * 0.5),
        ),
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  const _RingsPainter({
    required this.progress,
    required this.reveal,
    required this.animate,
  });

  final double progress;
  final double reveal;
  final bool animate;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final max = size.shortestSide / 2;
    // Fixed guide rings (the orbit track and an outer hairline).
    final guide = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.12 * reveal);
    canvas.drawCircle(c, max * 0.80 * reveal, guide);
    canvas.drawCircle(c, max * 0.56 * reveal, guide);
    if (!animate) return;
    // Three signal pulses spreading out from the disc.
    for (var i = 0; i < 3; i++) {
      final p = (progress * 6 + i / 3) % 1.0;
      final r = max * (0.3 + 0.7 * Curves.easeOut.transform(p));
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = AppColors.signal.withValues(
            alpha: 0.5 * (1 - p) * reveal,
          ),
      );
    }
  }

  @override
  bool shouldRepaint(_RingsPainter old) =>
      old.progress != progress || old.reveal != reveal || old.animate != animate;
}
