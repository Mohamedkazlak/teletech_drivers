import 'package:flutter/material.dart';

/// Accessibility-aware animation helpers.
abstract final class AppAnimations {
  static bool disabled(BuildContext context) {
    return MediaQuery.of(context).disableAnimations;
  }

  static Duration duration(
    BuildContext context,
    Duration preferred, {
    Duration reduced = Duration.zero,
  }) {
    return disabled(context) ? reduced : preferred;
  }

  static Duration stagger(BuildContext context, int index, {int cap = 8}) {
    if (disabled(context) || index >= cap) return Duration.zero;
    return Duration(milliseconds: 60 * index);
  }
}
