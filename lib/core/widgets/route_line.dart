import 'package:flutter/material.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/core/theme/app_motion.dart';
import 'package:teletech_drivers/core/widgets/animation_helpers.dart';

/// The route motif: origin dot, a line, destination ring, with the two place
/// names stacked beside it. Reads correctly in RTL.
class RouteLine extends StatelessWidget {
  const RouteLine({
    required this.from,
    required this.to,
    this.color = AppColors.deepBlue,
    this.live = false,
    super.key,
  });

  final String from;
  final String to;
  final Color color;

  /// Draws the line in the live colour (trip in progress).
  final bool live;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final lineColor = live ? AppColors.signal : AppColors.line;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 14,
            child: Column(
              children: [
                const SizedBox(height: 5),
                _Dot(color: color, filled: true),
                Expanded(
                  child: Center(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      decoration: BoxDecoration(
                        color: lineColor,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                ),
                _Dot(color: color, filled: false),
                const SizedBox(height: 5),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  from,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.inkMuted,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  to,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.filled});

  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? color : AppColors.white,
        border: Border.all(color: color, width: 2.5),
      ),
    );
  }
}

/// A larger, self-drawing route used as the empty-state illustration.
///
/// The curve draws itself once on first build (easeOut, 900 ms), then rests.
class RouteSketch extends StatefulWidget {
  const RouteSketch({this.size = const Size(132, 96), super.key});

  final Size size;

  @override
  State<RouteSketch> createState() => _RouteSketchState();
}

class _RouteSketchState extends State<RouteSketch>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppAnimations.disabled(context)) {
      _controller.value = 1;
    } else if (_controller.value == 0 && !_controller.isAnimating) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return SizedBox.fromSize(
      size: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _SketchPainter(
            progress: AppMotion.easeOut.transform(_controller.value),
            mirror: rtl,
          ),
        ),
      ),
    );
  }
}

class _SketchPainter extends CustomPainter {
  const _SketchPainter({required this.progress, required this.mirror});

  final double progress;
  final bool mirror;

  @override
  void paint(Canvas canvas, Size size) {
    if (mirror) {
      canvas
        ..translate(size.width, 0)
        ..scale(-1, 1);
    }
    final start = Offset(size.width * 0.12, size.height * 0.78);
    final end = Offset(size.width * 0.86, size.height * 0.24);
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(
        size.width * 0.5,
        size.height * 1.02,
        size.width * 0.44,
        size.height * 0.02,
        end.dx,
        end.dy,
      );

    // Ground ring behind the destination.
    canvas.drawCircle(
      end,
      22,
      Paint()..color = AppColors.paleBlue,
    );

    final track = Paint()
      ..color = AppColors.line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, track);

    final metric = path.computeMetrics().first;
    final drawn = metric.extractPath(0, metric.length * progress);
    canvas.drawPath(
      drawn,
      Paint()
        ..color = AppColors.deepBlue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawCircle(start, 6, Paint()..color = AppColors.deepBlue);
    final ring = Paint()
      ..color = AppColors.deepBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final endOpacity = ((progress - 0.75) / 0.25).clamp(0.0, 1.0);
    ring.color = AppColors.deepBlue.withValues(alpha: 0.25 + 0.75 * endOpacity);
    canvas.drawCircle(end, 7, ring);
    canvas.drawCircle(end, 2.5, Paint()..color = ring.color);
  }

  @override
  bool shouldRepaint(_SketchPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.mirror != mirror;
  }
}
