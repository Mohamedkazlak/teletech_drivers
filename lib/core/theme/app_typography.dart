import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Brand type: Readex Pro (one family for Latin and Arabic), Cairo fallback.
abstract final class AppTypography {
  static const String family = 'Readex Pro';

  /// Tabular figures so times, counts and distances never jitter.
  static const List<FontFeature> tabularFeatures = [
    FontFeature.tabularFigures(),
  ];

  static TextStyle apply(TextStyle? style, {FontWeight? weight, Color? color}) {
    try {
      return GoogleFonts.getFont(
        family,
        textStyle: style,
        fontWeight: weight ?? style?.fontWeight,
        color: color ?? style?.color,
      );
    } on Object {
      return GoogleFonts.cairo(
        textStyle: style,
        fontWeight: weight ?? style?.fontWeight,
        color: color ?? style?.color,
      );
    }
  }

  /// [style] with tabular figures switched on.
  static TextStyle? tabular(TextStyle? style) {
    return style?.copyWith(fontFeatures: tabularFeatures);
  }
}
