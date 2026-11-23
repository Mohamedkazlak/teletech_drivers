import 'package:flutter/material.dart';

/// Soft fade-through transition used globally for Material routes.
class FadeThroughPageTransitionsBuilder extends PageTransitionsBuilder {
  const FadeThroughPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final fadeIn = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );
    final fadeOut = Tween<double>(begin: 1, end: 0.92).animate(
      CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeInCubic),
    );

    return FadeTransition(
      opacity: fadeIn,
      child: FadeTransition(
        opacity: fadeOut,
        child: child,
      ),
    );
  }
}
