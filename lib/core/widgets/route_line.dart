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
    this.onDark = false,
    this.large = false,
    super.key,
  });

  final String from;
  final String to;
  final Color color;

  /// Trip in progress: the line turns to the live colour and a small light
  /// travels along it.
  final bool live;

  /// White text and marks, for the navy hero surface.
  final bool onDark;

  /// Bigger place names (details header).
  final bool large;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final markColor = onDark ? AppColors.white : color;
    final lineColor = live
        ? AppColors.signal
        : onDark
        ? AppColors.white.withValues(alpha: 0.28)
        : AppColors.line;
    final fromStyle = (large ? textTheme.bodyLarge : textTheme.bodyMedium)
        ?.copyWith(
          color: onDark
              ? AppColors.white.withValues(alpha: 0.72)
              : AppColors.inkMuted,
        );
    final toStyle = (large ? textTheme.titleLarge : textTheme.titleMedium)
        ?.copyWith(color: onDark ? AppColors.white : null);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 14,
            child: Column(
              children: [
                const SizedBox(height: 5),
                _Dot(color: markColor, filled: true, onDark: onDark),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: _Track(color: lineColor, live: live),
                  ),
                ),
                _Dot(color: markColor, filled: false, onDark: onDark),
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
                  maxLines: large ? 3 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: fromStyle,
                ),
                SizedBox(height: large ? 14 : 10),
                Text(
                  to,
                  maxLines: large ? 3 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: toStyle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The connecting line. When [live], a soft light runs down it on a loop.
class _Track extends StatefulWidget {
  const _Track({required this.color, required this.live});

  final Color color;
  final bool live;

  @override
  State<_Track> createState() => _TrackState();
}

class _TrackState extends State<_Track> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(_Track oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  void _sync() {
    final run = widget.live && !AppAnimations.disabled(context);
    if (run && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!run && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final line = Center(
      child: Container(
        width: 2,
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
    if (!_controller.isAnimating) return line;
    return Stack(
      children: [
        Positioned.fill(child: line),
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(
              painter: _TrackLightPainter(
                t: AppMotion.easeInOut.transform(_controller.value),
                color: widget.color,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TrackLightPainter extends CustomPainter {
  const _TrackLightPainter({required this.t, required this.color});

  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height * t;
    final center = Offset(size.width / 2, y);
    canvas.drawCircle(
      center,
      5,
      Paint()
        ..color = color.withValues(alpha: 0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
    canvas.drawCircle(center, 2.5, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_TrackLightPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.color != color;
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.filled, this.onDark = false});

  final Color color;
  final bool filled;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled
            ? color
            : (onDark ? Colors.transparent : AppColors.white),
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
