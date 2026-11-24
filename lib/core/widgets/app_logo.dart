import 'package:flutter/material.dart';
import 'package:teletech_drivers/core/widgets/teletech_logo.dart';

/// TeleTech brand mark, drawn as vectors by [TeleTechLogo].
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.height = 40,
    this.animated = false,
    this.heroTag,
    this.onDark = false,
    this.delay = Duration.zero,
  });

  /// Kept for anything that still needs the raster (e.g. notifications).
  static const String assetPath = 'assets/images/teletech_logo.png';
  static const String defaultHeroTag = 'teletech-logo';

  final double height;

  /// Plays the vector build-in (ellipses, wordmark wipe, ring ripple).
  final bool animated;
  final Object? heroTag;
  final bool onDark;

  /// Wait before the build-in starts.
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    Widget logo = TeleTechLogo(
      height: height,
      animate: animated,
      onDark: onDark,
      delay: delay,
    );

    final tag = heroTag;
    if (tag != null) {
      logo = Hero(tag: tag, child: logo);
    }
    return logo;
  }
}
