import 'package:flutter/material.dart';

/// Brand and semantic palette: TeleTech blue, evolved ("Ring & Route").
///
/// See DESIGN.md. Names kept from the original palette so every screen
/// picks up the new values without edits.
abstract final class AppColors {
  /// TeleTech blue. Primary actions and selection.
  static const Color deepBlue = Color(0xFF0B4DA2);

  /// Live / active state, focus, the ring pulse.
  static const Color signal = Color(0xFF2F7BEA);

  static const Color midBlue = Color(0xFF4A78BE);
  static const Color lightBlue = Color(0xFF8CA6D9);
  static const Color paleBlue = Color(0xFFEAF0FA);

  /// Ink: primary text and the dark hero surface.
  static const Color navy = Color(0xFF0B1F45);

  /// Deepest end of the hero surface.
  static const Color navyDeep = Color(0xFF071533);

  /// Secondary text. 5.3:1 on white.
  static const Color inkMuted = Color(0xFF5B6B86);

  static const Color white = Colors.white;
  static const Color scaffold = Color(0xFFF4F6FA);

  /// Hairline borders and dividers.
  static const Color line = Color(0xFFE3E8F1);

  static const Color success = Color(0xFF1F9D6B);
  static const Color warning = Color(0xFFE0A030);
  static const Color error = Color(0xFFD64545);

  static Color statusPending = warning;
  static Color statusApproved = midBlue;
  static Color statusAssigned = midBlue;
  static Color statusInProgress = signal;
  static Color statusCompleted = success;
  static Color statusRejected = error;

  /// Text colour for [color] on its own 12–16 % tint. Darkens light hues
  /// (amber, green) until they read at 4.5:1.
  static Color inkOn(Color color) {
    final hsl = HSLColor.fromColor(color);
    final lightness = (hsl.lightness * 0.62).clamp(0.0, 0.42);
    return hsl.withLightness(lightness).toColor();
  }
}
