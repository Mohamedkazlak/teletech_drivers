import 'package:flutter/material.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';

/// Reusable brand gradients.
abstract final class AppGradients {
  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.deepBlue, AppColors.midBlue],
  );

  static const LinearGradient soft = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.midBlue, AppColors.lightBlue],
  );
}
