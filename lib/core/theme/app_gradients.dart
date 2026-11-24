import 'package:flutter/material.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';

/// Reusable brand gradients. One dark hero surface per screen at most.
abstract final class AppGradients {
  /// TeleTech blue into deep navy. The hero surface.
  static const LinearGradient primary = LinearGradient(
    begin: AlignmentDirectional.topStart,
    end: AlignmentDirectional.bottomEnd,
    colors: [AppColors.deepBlue, AppColors.navy, AppColors.navyDeep],
    stops: [0, 0.62, 1],
  );

  static const LinearGradient soft = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.midBlue, AppColors.lightBlue],
  );
}
