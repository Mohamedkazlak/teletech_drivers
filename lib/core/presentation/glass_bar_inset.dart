import 'package:flutter/material.dart';

/// Exposes the floating bar's total height (pill, margin, and safe area).
///
/// Root-tab scrollables add this to their bottom padding. Detail routes sit
/// on the root navigator, outside this scope, so [of] is zero there.
class GlassBarInset extends InheritedWidget {
  const GlassBarInset({
    required this.totalHeight,
    required super.child,
    super.key,
  });

  /// Occupied height at the bottom of the screen. Zero while the bar is hidden.
  final double totalHeight;

  static double of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<GlassBarInset>();
    return scope?.totalHeight ?? 0;
  }

  /// Adds the bar clearance to an existing list padding.
  static EdgeInsetsDirectional listPadding(
    BuildContext context,
    EdgeInsetsDirectional padding,
  ) {
    final extra = of(context);
    if (extra == 0) return padding;
    return EdgeInsetsDirectional.fromSTEB(
      padding.start,
      padding.top,
      padding.end,
      padding.bottom + extra,
    );
  }

  @override
  bool updateShouldNotify(GlassBarInset oldWidget) {
    return totalHeight != oldWidget.totalHeight;
  }
}

/// Lifts a nested scaffold FAB above the floating bar.
class GlassBarFabLocation extends FloatingActionButtonLocation {
  const GlassBarFabLocation({required this.base, required this.lift});

  final FloatingActionButtonLocation base;
  final double lift;

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final origin = base.getOffset(scaffoldGeometry);
    return Offset(origin.dx, origin.dy - lift);
  }
}
