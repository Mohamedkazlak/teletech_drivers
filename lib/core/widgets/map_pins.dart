import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/core/widgets/animation_helpers.dart';

/// Map pin in the brand's ring style: a teardrop with the logo's white ring
/// inside. Drops in with a small bounce the first time it appears.
///
/// Its tip is the bottom-centre, so use `alignment: Alignment.topCenter` on
/// the [Marker] (the pin sits above the point).
class BrandPin extends StatefulWidget {
  const BrandPin({
    this.color = AppColors.deepBlue,
    this.size = 40,
    this.animate = true,
    super.key,
  });

  final Color color;

  /// Pin width; height is 1.25× this.
  final double size;
  final bool animate;

  @override
  State<BrandPin> createState() => _BrandPinState();
}

class _BrandPinState extends State<BrandPin>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.animate || AppAnimations.disabled(context)) {
      _drop.value = 1;
    } else if (_drop.value == 0 && !_drop.isAnimating) {
      _drop.forward();
    }
  }

  @override
  void dispose() {
    _drop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.size;
    final h = w * 1.25;
    return SizedBox(
      width: w,
      height: h,
      child: AnimatedBuilder(
        animation: _drop,
        builder: (context, child) {
          final t = Curves.easeOutBack.transform(_drop.value);
          return Opacity(
            opacity: _drop.value.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, -h * 0.35 * (1 - t)),
              child: Transform.scale(
                scale: 0.7 + 0.3 * t,
                alignment: Alignment.bottomCenter,
                child: child,
              ),
            ),
          );
        },
        child: CustomPaint(painter: _PinPainter(widget.color)),
      ),
    );
  }
}

class _PinPainter extends CustomPainter {
  const _PinPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2 * 0.9;
    final head = Offset(size.width / 2, r + size.width * 0.05);
    final tip = Offset(size.width / 2, size.height - 1);

    final body = ui.Path.combine(
      PathOperation.union,
      ui.Path()..addOval(Rect.fromCircle(center: head, radius: r)),
      ui.Path()
        ..moveTo(head.dx - r * 0.72, head.dy + r * 0.7)
        ..quadraticBezierTo(head.dx - r * 0.2, head.dy + r * 1.3, tip.dx, tip.dy)
        ..quadraticBezierTo(
          head.dx + r * 0.2,
          head.dy + r * 1.3,
          head.dx + r * 0.72,
          head.dy + r * 0.7,
        )
        ..close(),
    );

    canvas.drawShadow(body, AppColors.navyDeep, 3, false);
    canvas.drawPath(body, Paint()..color = color);
    canvas.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = AppColors.white,
    );
    // Logo ring + centre dot.
    canvas.drawCircle(
      head,
      r * 0.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = r * 0.16
        ..color = AppColors.white,
    );
    canvas.drawCircle(head, r * 0.17, Paint()..color = AppColors.white);
  }

  @override
  bool shouldRepaint(_PinPainter oldDelegate) => oldDelegate.color != color;
}

/// Small ringed dot for a trip's origin.
class OriginDot extends StatelessWidget {
  const OriginDot({this.color = AppColors.deepBlue, this.size = 22, super.key});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.white,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: size * 0.22),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDeep.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }
}

/// Glides a [MapController] to [target] instead of jumping.
///
/// Runs on its own [Ticker], so it never outlives a State's ticker; if the
/// map goes away mid-flight the glide just stops. Pass [instant] (e.g. when
/// animations are off) to move straight there.
Future<void> animateMapMove({
  required MapController controller,
  required LatLng target,
  double? zoom,
  bool instant = false,
  Duration duration = const Duration(milliseconds: 650),
}) {
  final MapCamera camera;
  try {
    camera = controller.camera;
  } on Object {
    return Future.value();
  }
  final endZoom = zoom ?? camera.zoom;
  if (instant) {
    controller.move(target, endZoom);
    return Future.value();
  }
  final startLat = camera.center.latitude;
  final startLng = camera.center.longitude;
  final startZoom = camera.zoom;
  const curve = Cubic(0.65, 0, 0.35, 1);
  final done = Completer<void>();
  late final Ticker ticker;
  ticker = Ticker((elapsed) {
    final raw = elapsed.inMicroseconds / duration.inMicroseconds;
    final t = curve.transform(raw.clamp(0.0, 1.0));
    try {
      controller.move(
        LatLng(
          startLat + (target.latitude - startLat) * t,
          startLng + (target.longitude - startLng) * t,
        ),
        startZoom + (endZoom - startZoom) * t,
      );
    } on Object {
      ticker.dispose();
      if (!done.isCompleted) done.complete();
      return;
    }
    if (raw >= 1) {
      ticker.dispose();
      if (!done.isCompleted) done.complete();
    }
  });
  ticker.start();
  return done.future;
}

/// Gently tints raster map tiles toward the brand palette (cooler, calmer
/// colours) so the map sits with the rest of the UI.
Widget brandTileBuilder(BuildContext context, Widget tileWidget, TileImage tile) {
  return ColorFiltered(colorFilter: _brandTileFilter, child: tileWidget);
}

/// Slight desaturation plus a cool blue cast; keeps roads and labels legible.
const ColorFilter _brandTileFilter = ColorFilter.matrix(<double>[
  0.80, 0.12, 0.04, 0, 4, //
  0.06, 0.84, 0.08, 0, 6, //
  0.06, 0.10, 0.92, 0, 14, //
  0, 0, 0, 1, 0, //
]);
