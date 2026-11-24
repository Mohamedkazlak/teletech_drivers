import 'package:flutter/animation.dart';

/// Motion tokens. See DESIGN.md → Motion.
///
/// Strong custom curves (Emil Kowalski's set): built-in easings are too weak
/// to feel intentional. Never ease-in on UI.
abstract final class AppMotion {
  /// Entrances, feedback. Starts fast, settles softly.
  static const Curve easeOut = Cubic(0.23, 1, 0.32, 1);

  /// Things moving across the screen (indicators, thumbs).
  static const Curve easeInOut = Cubic(0.77, 0, 0.175, 1);

  /// Sheets and drawers (iOS-like).
  static const Curve drawer = Cubic(0.32, 0.72, 0, 1);

  static const Duration press = Duration(milliseconds: 120);
  static const Duration quick = Duration(milliseconds: 180);
  static const Duration standard = Duration(milliseconds: 260);
  static const Duration emphasized = Duration(milliseconds: 420);

  /// Exits run faster than entrances.
  static const Duration exit = Duration(milliseconds: 160);

  /// Non-uniform list stagger: quick at first, then compressing, capped.
  static const List<int> _staggerMs = [0, 50, 90, 120, 145, 165, 180, 190];

  static Duration staggerAt(int index) {
    if (index < 0) return Duration.zero;
    final ms = index < _staggerMs.length ? _staggerMs[index] : _staggerMs.last;
    return Duration(milliseconds: ms);
  }
}
