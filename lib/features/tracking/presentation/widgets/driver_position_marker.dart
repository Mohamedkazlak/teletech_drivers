import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';

/// Blue driver dot with accuracy halo, heading arrow, and gentle pulse.
class DriverPositionMarker extends StatefulWidget {
  const DriverPositionMarker({
    required this.headingDegrees,
    this.accuracyMeters = 20,
    this.pulse = true,
    super.key,
  });

  final double headingDegrees;
  final double accuracyMeters;
  final bool pulse;

  @override
  State<DriverPositionMarker> createState() => _DriverPositionMarkerState();
}

class _DriverPositionMarkerState extends State<DriverPositionMarker>
    with SingleTickerProviderStateMixin {
  AnimationController? _pulse;

  @override
  void initState() {
    super.initState();
    if (widget.pulse) {
      _pulse = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1600),
      )..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final halo = (widget.accuracyMeters.clamp(12, 48)).toDouble();

    Widget core = SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: halo,
            height: halo,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.midBlue.withValues(alpha: 0.22),
            ),
          ),
          Transform.rotate(
            angle: widget.headingDegrees * math.pi / 180,
            child: const Icon(
              Icons.navigation,
              color: AppColors.deepBlue,
              size: 28,
            ),
          ),
          Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: AppColors.deepBlue,
              shape: BoxShape.circle,
              border: Border.fromBorderSide(
                BorderSide(color: AppColors.white, width: 2),
              ),
            ),
          ),
        ],
      ),
    );

    if (disableAnimations || _pulse == null || !widget.pulse) return core;

    return AnimatedBuilder(
      animation: _pulse!,
      builder: (context, child) {
        final scale = 0.92 + (_pulse!.value * 0.08);
        return Transform.scale(scale: scale, child: child);
      },
      child: core,
    );
  }
}
