import 'package:flutter/material.dart';

/// Brand and semantic palette extracted from the TeleTech logo.
abstract final class AppColors {
  static const Color deepBlue = Color(0xFF0B4DA2);
  static const Color midBlue = Color(0xFF4A78BE);
  static const Color lightBlue = Color(0xFF8CA6D9);
  static const Color paleBlue = Color(0xFFE8EEF9);
  static const Color navy = Color(0xFF062B5C);
  static const Color white = Colors.white;
  static const Color scaffold = Color(0xFFF6F9FE);

  static const Color success = Color(0xFF2E9E6B);
  static const Color warning = Color(0xFFE0A030);
  static const Color error = Color(0xFFD64545);

  static Color statusPending = warning;
  static Color statusApproved = midBlue;
  static Color statusAssigned = midBlue;
  static Color statusInProgress = deepBlue;
  static Color statusCompleted = success;
  static Color statusRejected = error;
}
