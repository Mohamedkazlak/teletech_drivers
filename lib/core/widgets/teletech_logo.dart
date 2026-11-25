import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:teletech_drivers/core/theme/app_motion.dart';
import 'package:teletech_drivers/core/widgets/animation_helpers.dart';

/// The TeleTech logo, drawn as vectors (see assets/branding/teletech_logo.svg).
///
/// Crisp at any size, recolourable, and every layer can animate: the
/// ellipses sweep open, the wordmark wipes in, and the ring mark ripples.
class TeleTechLogo extends StatefulWidget {
  const TeleTechLogo({
    this.height = 40,
    this.animate = false,
    this.onDark = false,
    this.delay = Duration.zero,
    super.key,
  });

  final double height;

  /// Plays the build-in once when first shown.
  final bool animate;

  /// White-tinted variant for navy surfaces.
  final bool onDark;

  final Duration delay;

  /// Intrinsic logo size in design units (the SVG viewBox).
  static const Size designSize = Size(646, 184);

  @override
  State<TeleTechLogo> createState() => _TeleTechLogoState();
}

class _TeleTechLogoState extends State<TeleTechLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  var _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!widget.animate || AppAnimations.disabled(context)) {
      _controller.value = 1;
      return;
    }
    Future<void>.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width =
        widget.height *
        TeleTechLogo.designSize.width /
        TeleTechLogo.designSize.height;
    return Semantics(
      label: 'TeleTech',
      image: true,
      child: SizedBox(
        width: width,
        height: widget.height,
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(
              painter: TeleTechLogoPainter(
                progress: _controller.value,
                onDark: widget.onDark,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints the logo into its box. [progress] 0 → 1 runs the build-in.
class TeleTechLogoPainter extends CustomPainter {
  const TeleTechLogoPainter({this.progress = 1, this.onDark = false});

  final double progress;
  final bool onDark;

  static const _outer = Color(0xFF4A76BA);
  static const _light = Color(0xFF86A2D1);
  static const _dark = Color(0xFF0B4DA2);
  static const _white = Color(0xFFFFFFFF);

  double _phase(double start, double end) {
    final t = ((progress - start) / (end - start)).clamp(0.0, 1.0);
    return AppMotion.easeOut.transform(t);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(
      size.width / TeleTechLogo.designSize.width,
      size.height / TeleTechLogo.designSize.height,
    );
    canvas
      ..save()
      ..scale(scale)
      ..translate(-60, -26);

    final outer = onDark ? _white.withValues(alpha: 0.16) : _outer;
    final light = onDark ? _white.withValues(alpha: 0.22) : _light;
    final dark = onDark ? _white.withValues(alpha: 0.12) : _dark;

    // Ellipses sweep open from the ring mark's side, staggered.
    _ellipse(canvas, const Offset(365, 118), 295, 82, outer, _phase(0, 0.5));
    _ellipse(canvas, const Offset(325, 116), 245, 66, light, _phase(0.08, 0.58));
    _ellipse(canvas, const Offset(220, 115), 150, 37, dark, _phase(0.16, 0.66));

    // Wordmark wipes in left to right.
    final wipe = _phase(0.3, 0.8);
    if (wipe > 0) {
      canvas
        ..save()
        ..clipRect(Rect.fromLTWH(180, 60, 380 * wipe, 110));
      canvas.drawPath(wordmarkPath(), Paint()..color = _white);
      canvas.restore();
    }

    // Ring mark: crescent, then the two rings ripple out.
    final mark = _phase(0.1, 0.55);
    if (mark > 0) {
      final c = const Offset(642, 117);
      canvas
        ..save()
        ..translate(c.dx, c.dy)
        ..scale(0.6 + 0.4 * mark)
        ..translate(-c.dx, -c.dy);
      final alpha = mark;
      canvas.drawCircle(c, 54, Paint()..color = _white.withValues(alpha: alpha));
      canvas.drawCircle(
        const Offset(653, 117),
        47,
        Paint()..color = (onDark ? const Color(0xFF173C7A) : _outer)
            .withValues(alpha: alpha),
      );
      canvas.restore();
    }
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = _white;
    final r1 = _phase(0.4, 0.85);
    if (r1 > 0) {
      canvas.drawCircle(
        const Offset(655, 117),
        34 * (0.4 + 0.6 * r1),
        ringPaint
          ..strokeWidth = 5
          ..color = _white.withValues(alpha: r1),
      );
    }
    final r2 = _phase(0.5, 0.95);
    if (r2 > 0) {
      canvas.drawCircle(
        const Offset(657, 117.5),
        24 * (0.4 + 0.6 * r2),
        ringPaint
          ..strokeWidth = 3
          ..color = _white.withValues(alpha: r2),
      );
    }
    canvas.restore();
  }

  void _ellipse(
    Canvas canvas,
    Offset center,
    double rx,
    double ry,
    Color color,
    double t,
  ) {
    if (t <= 0) return;
    // Grows from its right end (where the ring mark sits).
    final right = center.dx + rx;
    final width = 2 * rx * (0.15 + 0.85 * t);
    final rect = Rect.fromLTRB(
      right - width,
      center.dy - ry * (0.6 + 0.4 * t),
      right,
      center.dy + ry * (0.6 + 0.4 * t),
    );
    canvas.drawOval(rect, Paint()..color = color.withValues(alpha: color.a * t));
  }

  static Path? _cachedWordmark;

  /// "TeleTech" as glyph outlines, in design units.
  static Path wordmarkPath() {
    return _cachedWordmark ??= Path()
      ..fillType = PathFillType.nonZero
    ..moveTo(235.35, 87.51)
    ..lineTo(235.35, 95.20)
    ..lineTo(220.04, 95.20)
    ..lineTo(220.04, 145.00)
    ..lineTo(210.61, 145.00)
    ..lineTo(210.61, 95.20)
    ..lineTo(195.23, 95.20)
    ..lineTo(195.23, 87.51)
    ..close()
    ..moveTo(284.65, 125.73)
    ..lineTo(249.82, 125.73)
    ..quadraticBezierTo(250.24, 131.19, 253.88, 134.49)
    ..quadraticBezierTo(257.51, 137.80, 262.81, 137.80)
    ..quadraticBezierTo(270.42, 137.80, 273.56, 131.43)
    ..lineTo(283.74, 131.43)
    ..quadraticBezierTo(281.67, 137.72, 276.25, 141.73)
    ..quadraticBezierTo(270.83, 145.74, 262.81, 145.74)
    ..quadraticBezierTo(256.27, 145.74, 251.10, 142.81)
    ..quadraticBezierTo(245.93, 139.87, 243.00, 134.54)
    ..quadraticBezierTo(240.06, 129.20, 240.06, 122.17)
    ..quadraticBezierTo(240.06, 115.14, 242.91, 109.80)
    ..quadraticBezierTo(245.77, 104.47, 250.94, 101.57)
    ..quadraticBezierTo(256.11, 98.68, 262.81, 98.68)
    ..quadraticBezierTo(269.26, 98.68, 274.31, 101.49)
    ..quadraticBezierTo(279.35, 104.30, 282.17, 109.39)
    ..quadraticBezierTo(284.98, 114.48, 284.98, 121.09)
    ..quadraticBezierTo(284.98, 123.66, 284.65, 125.73)
    ..close()
    ..moveTo(275.13, 118.12)
    ..quadraticBezierTo(275.05, 112.90, 271.41, 109.76)
    ..quadraticBezierTo(267.77, 106.62, 262.40, 106.62)
    ..quadraticBezierTo(257.51, 106.62, 254.04, 109.72)
    ..quadraticBezierTo(250.57, 112.82, 249.90, 118.12)
    ..close()
    ..moveTo(302.02, 83.79)
    ..lineTo(302.02, 145.00)
    ..lineTo(292.59, 145.00)
    ..lineTo(292.59, 83.79)
    ..close()
    ..moveTo(354.22, 125.73)
    ..lineTo(319.39, 125.73)
    ..quadraticBezierTo(319.80, 131.19, 323.44, 134.49)
    ..quadraticBezierTo(327.08, 137.80, 332.38, 137.80)
    ..quadraticBezierTo(339.99, 137.80, 343.13, 131.43)
    ..lineTo(353.31, 131.43)
    ..quadraticBezierTo(351.24, 137.72, 345.82, 141.73)
    ..quadraticBezierTo(340.40, 145.74, 332.38, 145.74)
    ..quadraticBezierTo(325.84, 145.74, 320.67, 142.81)
    ..quadraticBezierTo(315.50, 139.87, 312.57, 134.54)
    ..quadraticBezierTo(309.63, 129.20, 309.63, 122.17)
    ..quadraticBezierTo(309.63, 115.14, 312.48, 109.80)
    ..quadraticBezierTo(315.34, 104.47, 320.51, 101.57)
    ..quadraticBezierTo(325.68, 98.68, 332.38, 98.68)
    ..quadraticBezierTo(338.83, 98.68, 343.88, 101.49)
    ..quadraticBezierTo(348.92, 104.30, 351.73, 109.39)
    ..quadraticBezierTo(354.55, 114.48, 354.55, 121.09)
    ..quadraticBezierTo(354.55, 123.66, 354.22, 125.73)
    ..close()
    ..moveTo(344.70, 118.12)
    ..quadraticBezierTo(344.62, 112.90, 340.98, 109.76)
    ..quadraticBezierTo(337.34, 106.62, 331.96, 106.62)
    ..quadraticBezierTo(327.08, 106.62, 323.61, 109.72)
    ..quadraticBezierTo(320.13, 112.82, 319.47, 118.12)
    ..close()
    ..moveTo(399.30, 87.51)
    ..lineTo(399.30, 95.20)
    ..lineTo(383.99, 95.20)
    ..lineTo(383.99, 145.00)
    ..lineTo(374.56, 145.00)
    ..lineTo(374.56, 95.20)
    ..lineTo(359.18, 95.20)
    ..lineTo(359.18, 87.51)
    ..close()
    ..moveTo(448.60, 125.73)
    ..lineTo(413.77, 125.73)
    ..quadraticBezierTo(414.19, 131.19, 417.83, 134.49)
    ..quadraticBezierTo(421.47, 137.80, 426.76, 137.80)
    ..quadraticBezierTo(434.37, 137.80, 437.51, 131.43)
    ..lineTo(447.69, 131.43)
    ..quadraticBezierTo(445.62, 137.72, 440.20, 141.73)
    ..quadraticBezierTo(434.78, 145.74, 426.76, 145.74)
    ..quadraticBezierTo(420.23, 145.74, 415.06, 142.81)
    ..quadraticBezierTo(409.89, 139.87, 406.95, 134.54)
    ..quadraticBezierTo(404.01, 129.20, 404.01, 122.17)
    ..quadraticBezierTo(404.01, 115.14, 406.87, 109.80)
    ..quadraticBezierTo(409.72, 104.47, 414.89, 101.57)
    ..quadraticBezierTo(420.06, 98.68, 426.76, 98.68)
    ..quadraticBezierTo(433.21, 98.68, 438.26, 101.49)
    ..quadraticBezierTo(443.31, 104.30, 446.12, 109.39)
    ..quadraticBezierTo(448.93, 114.48, 448.93, 121.09)
    ..quadraticBezierTo(448.93, 123.66, 448.60, 125.73)
    ..close()
    ..moveTo(439.09, 118.12)
    ..quadraticBezierTo(439.00, 112.90, 435.36, 109.76)
    ..quadraticBezierTo(431.72, 106.62, 426.35, 106.62)
    ..quadraticBezierTo(421.47, 106.62, 417.99, 109.72)
    ..quadraticBezierTo(414.52, 112.82, 413.86, 118.12)
    ..close()
    ..moveTo(475.73, 98.68)
    ..quadraticBezierTo(484.00, 98.68, 489.42, 102.61)
    ..quadraticBezierTo(494.84, 106.53, 496.74, 113.81)
    ..lineTo(486.57, 113.81)
    ..quadraticBezierTo(485.33, 110.42, 482.60, 108.52)
    ..quadraticBezierTo(479.87, 106.62, 475.73, 106.62)
    ..quadraticBezierTo(469.94, 106.62, 466.51, 110.71)
    ..quadraticBezierTo(463.08, 114.81, 463.08, 122.17)
    ..quadraticBezierTo(463.08, 129.53, 466.51, 133.67)
    ..quadraticBezierTo(469.94, 137.80, 475.73, 137.80)
    ..quadraticBezierTo(483.92, 137.80, 486.57, 130.61)
    ..lineTo(496.74, 130.61)
    ..quadraticBezierTo(494.76, 137.56, 489.30, 141.65)
    ..quadraticBezierTo(483.84, 145.74, 475.73, 145.74)
    ..quadraticBezierTo(469.20, 145.74, 464.15, 142.81)
    ..quadraticBezierTo(459.10, 139.87, 456.25, 134.54)
    ..quadraticBezierTo(453.40, 129.20, 453.40, 122.17)
    ..quadraticBezierTo(453.40, 115.14, 456.25, 109.80)
    ..quadraticBezierTo(459.10, 104.47, 464.15, 101.57)
    ..quadraticBezierTo(469.20, 98.68, 475.73, 98.68)
    ..close()
    ..moveTo(546.21, 118.12)
    ..lineTo(546.21, 145.00)
    ..lineTo(536.86, 145.00)
    ..lineTo(536.86, 119.52)
    ..quadraticBezierTo(536.86, 113.40, 533.80, 110.13)
    ..quadraticBezierTo(530.74, 106.87, 525.45, 106.87)
    ..quadraticBezierTo(520.15, 106.87, 517.05, 110.13)
    ..quadraticBezierTo(513.95, 113.40, 513.95, 119.52)
    ..lineTo(513.95, 145.00)
    ..lineTo(504.52, 145.00)
    ..lineTo(504.52, 83.79)
    ..lineTo(513.95, 83.79)
    ..lineTo(513.95, 104.72)
    ..quadraticBezierTo(516.35, 101.82, 520.03, 100.25)
    ..quadraticBezierTo(523.71, 98.68, 528.09, 98.68)
    ..quadraticBezierTo(533.31, 98.68, 537.40, 100.91)
    ..quadraticBezierTo(541.49, 103.14, 543.85, 107.53)
    ..quadraticBezierTo(546.21, 111.91, 546.21, 118.12)
    ..close();
  }

  @override
  bool shouldRepaint(TeleTechLogoPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.onDark != onDark;
  }
}
