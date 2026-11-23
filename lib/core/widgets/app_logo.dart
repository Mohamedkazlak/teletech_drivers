import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:teletech_drivers/core/widgets/animation_helpers.dart';

/// TeleTech brand mark from [assets/images/teletech_logo.png].
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.height = 40,
    this.animated = false,
    this.heroTag,
  });

  static const String assetPath = 'assets/images/teletech_logo.png';
  static const String defaultHeroTag = 'teletech-logo';

  final double height;
  final bool animated;
  final Object? heroTag;

  @override
  Widget build(BuildContext context) {
    Widget logo = Semantics(
      label: 'TeleTech',
      image: true,
      child: Image.asset(
        assetPath,
        height: height,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );

    final tag = heroTag;
    if (tag != null) {
      logo = Hero(tag: tag, child: logo);
    }

    if (!animated || AppAnimations.disabled(context)) {
      return logo;
    }

    return logo
        .animate()
        .fadeIn(duration: 600.ms, curve: Curves.easeOut)
        .scale(
          begin: const Offset(0.85, 0.85),
          end: const Offset(1, 1),
          duration: 600.ms,
          curve: Curves.easeOutBack,
        )
        .shimmer(delay: 200.ms, duration: 800.ms);
  }
}
