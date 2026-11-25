import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/core/theme/app_motion.dart';
import 'package:teletech_drivers/core/theme/app_theme.dart';
import 'package:teletech_drivers/core/widgets/animation_helpers.dart';

/// Shows a short "done" moment over the whole app: a check that draws itself
/// inside expanding brand rings, plus [message]. Dismisses itself (or on tap).
///
/// Completes when the moment is gone, so callers can `await` it before
/// navigating away.
Future<void> showSuccessMoment(
  BuildContext context, {
  required String message,
  Duration hold = const Duration(milliseconds: 1250),
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return Future.value();
  HapticFeedback.heavyImpact();
  // ignore: deprecated_member_use
  SemanticsService.announce(message, Directionality.of(context));

  final done = Completer<void>();
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _SuccessMoment(
      message: message,
      hold: hold,
      onDone: () {
        if (done.isCompleted) return;
        entry.remove();
        done.complete();
      },
    ),
  );
  overlay.insert(entry);
  return done.future;
}

class _SuccessMoment extends StatefulWidget {
  const _SuccessMoment({
    required this.message,
    required this.hold,
    required this.onDone,
  });

  final String message;
  final Duration hold;
  final VoidCallback onDone;

  @override
  State<_SuccessMoment> createState() => _SuccessMomentState();
}

class _SuccessMomentState extends State<_SuccessMoment>
    with TickerProviderStateMixin {
  late final AnimationController _enter = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final AnimationController _exit = AnimationController(
    vsync: this,
    duration: AppMotion.standard,
  );
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _enter.forward();
    _timer = Timer(widget.hold, _close);
  }

  Future<void> _close() async {
    _timer?.cancel();
    if (_exit.isAnimating || _exit.isCompleted) return;
    await _exit.forward();
    widget.onDone();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _enter.dispose();
    _exit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = AppAnimations.disabled(context);
    if (still) _enter.value = 1;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _close,
      child: AnimatedBuilder(
        animation: Listenable.merge([_enter, _exit]),
        builder: (context, _) {
          final t = _enter.value;
          final out = AppMotion.easeOut.transform(_exit.value);
          final pop = AppMotion.easeOut.transform((t / 0.45).clamp(0, 1));
          return Opacity(
            opacity: 1 - out,
            child: ColoredBox(
              color: AppColors.navyDeep.withValues(alpha: 0.32 * pop),
              child: Center(
                child: Transform.scale(
                  scale: (0.86 + 0.14 * pop) * (1 - 0.04 * out),
                  child: Material(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(28),
                    elevation: 0,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 280),
                      padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: AppTheme.floatingShadow(opacity: 0.25),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox.square(
                            dimension: 112,
                            child: CustomPaint(
                              painter: _CheckBurstPainter(t: t),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Opacity(
                            opacity: ((t - 0.35) / 0.4).clamp(0, 1),
                            child: Text(
                              widget.message,
                              textAlign: TextAlign.center,
                              style: textTheme.titleMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CheckBurstPainter extends CustomPainter {
  const _CheckBurstPainter({required this.t});

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;

    // Two rings ripple out once, like the logo's signal.
    for (var i = 0; i < 2; i++) {
      final p = ((t - i * 0.12) / 0.7).clamp(0.0, 1.0);
      if (p <= 0 || p >= 1) continue;
      final e = AppMotion.easeOut.transform(p);
      canvas.drawCircle(
        c,
        r * (0.5 + 0.5 * e),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = AppColors.success.withValues(alpha: 0.5 * (1 - p)),
      );
    }

    // Disc.
    final disc = AppMotion.easeOut.transform((t / 0.4).clamp(0, 1));
    final bounce = 1 + 0.08 * math.sin(math.pi * disc);
    canvas.drawCircle(
      c,
      r * 0.48 * disc * bounce,
      Paint()..color = AppColors.success,
    );

    // Check mark draws itself.
    final draw = AppMotion.easeOut.transform(((t - 0.3) / 0.45).clamp(0, 1));
    if (draw <= 0) return;
    final path = Path()
      ..moveTo(c.dx - r * 0.2, c.dy + r * 0.01)
      ..lineTo(c.dx - r * 0.05, c.dy + r * 0.16)
      ..lineTo(c.dx + r * 0.23, c.dy - r * 0.14);
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * draw),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.085
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = AppColors.white,
    );
  }

  @override
  bool shouldRepaint(_CheckBurstPainter oldDelegate) => oldDelegate.t != t;
}
