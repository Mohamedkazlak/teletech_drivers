import 'package:flutter/material.dart';
import 'package:teletech_drivers/core/theme/app_motion.dart';

/// Shared-axis page transition that follows text direction.
///
/// The incoming page slides a short distance from the reading-forward side
/// and fades in. The page underneath drifts back and dims slightly, so pushing
/// and popping feel spatially consistent in both English and Arabic. Under
/// "Remove animations" only a crossfade remains.
class AppPageTransitionsBuilder extends PageTransitionsBuilder {
  const AppPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final enter = CurvedAnimation(
      parent: animation,
      curve: AppMotion.easeOut,
      reverseCurve: AppMotion.easeOut.flipped,
    );

    if (reduceMotion) {
      return FadeTransition(opacity: enter, child: child);
    }

    final rtl = Directionality.of(context) == TextDirection.rtl;
    final sign = rtl ? -1.0 : 1.0;
    final leave = CurvedAnimation(
      parent: secondaryAnimation,
      curve: AppMotion.easeOut,
      reverseCurve: AppMotion.easeOut.flipped,
    );

    return SlideTransition(
      position: Tween<Offset>(
        begin: Offset(0.0, 0),
        end: Offset(-0.06 * sign, 0),
      ).animate(leave),
      child: FadeTransition(
        opacity: Tween<double>(begin: 1, end: 0.6).animate(leave),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: Offset(0.12 * sign, 0),
            end: Offset.zero,
          ).animate(enter),
          child: FadeTransition(
            opacity: Tween<double>(begin: 0, end: 1).animate(
              CurvedAnimation(
                parent: animation,
                curve: const Interval(0, 0.6, curve: Curves.easeOut),
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
