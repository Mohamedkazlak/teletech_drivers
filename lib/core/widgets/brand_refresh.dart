import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/core/theme/app_motion.dart';
import 'package:teletech_drivers/core/theme/app_theme.dart';
import 'package:teletech_drivers/core/widgets/animation_helpers.dart';

/// Pull-to-refresh with the logo's rings as the spinner.
///
/// Drop-in replacement for [RefreshIndicator]: same [onRefresh] and scrollable
/// [child]. The rings appear while pulling, tighten when far enough to
/// release, and spin (in opposite directions) while refreshing.
class BrandRefresh extends StatefulWidget {
  const BrandRefresh({
    required this.onRefresh,
    required this.child,
    this.edgeOffset = 0,
    super.key,
  });

  final RefreshCallback onRefresh;
  final Widget child;

  /// Distance from the top where the spinner sits (e.g. below a header).
  final double edgeOffset;

  @override
  State<BrandRefresh> createState() => _BrandRefreshState();
}

class _BrandRefreshState extends State<BrandRefresh>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  RefreshIndicatorStatus? _status;

  void _onStatus(RefreshIndicatorStatus? status) {
    if (!mounted) return;
    if (status == RefreshIndicatorStatus.armed &&
        _status != RefreshIndicatorStatus.armed) {
      HapticFeedback.selectionClick();
    }
    final spinning =
        status == RefreshIndicatorStatus.snap ||
        status == RefreshIndicatorStatus.refresh;
    if (spinning && !AppAnimations.disabled(context)) {
      if (!_spin.isAnimating) _spin.repeat();
    } else {
      _spin.stop();
    }
    setState(() => _status = status);
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;
    final visible =
        status != null &&
        status != RefreshIndicatorStatus.done &&
        status != RefreshIndicatorStatus.canceled;
    final armed = status != null && status != RefreshIndicatorStatus.drag;
    final duration = AppAnimations.duration(context, AppMotion.quick);

    return Stack(
      children: [
        RefreshIndicator.noSpinner(
          onRefresh: widget.onRefresh,
          onStatusChange: _onStatus,
          child: widget.child,
        ),
        PositionedDirectional(
          top: widget.edgeOffset + 14,
          start: 0,
          end: 0,
          child: IgnorePointer(
            child: Center(
              child: AnimatedOpacity(
                duration: duration,
                opacity: visible ? 1 : 0,
                child: AnimatedScale(
                  duration: AppAnimations.duration(context, AppMotion.standard),
                  curve: AppMotion.easeOut,
                  scale: !visible
                      ? 0.6
                      : armed
                      ? 1
                      : 0.82,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                      boxShadow: AppTheme.floatingShadow(opacity: 0.16),
                    ),
                    child: AnimatedBuilder(
                      animation: _spin,
                      builder: (context, _) => CustomPaint(
                        painter: _RingSpinnerPainter(
                          t: _spin.value,
                          armed: armed,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RingSpinnerPainter extends CustomPainter {
  const _RingSpinnerPainter({required this.t, required this.armed});

  final double t;
  final bool armed;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final color = armed ? AppColors.deepBlue : AppColors.lightBlue;
    final angle = t * 2 * math.pi;

    // Outer ring: three-quarter arc turning clockwise.
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: 13),
      angle - math.pi / 2,
      math.pi * 1.5,
      false,
      stroke
        ..color = color
        ..strokeWidth = 3,
    );
    // Inner ring: half arc turning the other way.
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: 7),
      -angle * 1.4 + math.pi / 2,
      math.pi,
      false,
      stroke
        ..color = color.withValues(alpha: 0.7)
        ..strokeWidth = 2.4,
    );
    canvas.drawCircle(c, 2, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_RingSpinnerPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.armed != armed;
}
