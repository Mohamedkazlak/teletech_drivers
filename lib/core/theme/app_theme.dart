import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/core/theme/fade_through_page_transitions.dart';

/// Light Material 3 theme for TeleTech Drivers.
abstract final class AppTheme {
  static const double cardRadius = 16;
  static const double controlRadius = 14;

  static const double controlHeight = 52;

  /// Finite width so a button can live in a [Row] or dialog action bar.
  /// [Size.fromHeight] is infinite width and crashes those layouts.
  static const Size controlMinimumSize = Size(64, controlHeight);

  static ThemeData get light {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.deepBlue,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.deepBlue,
          secondary: AppColors.midBlue,
          tertiary: AppColors.lightBlue,
          surface: AppColors.white,
          surfaceContainerHighest: AppColors.paleBlue,
          onPrimary: AppColors.white,
          error: AppColors.error,
        );

    // google_fonts 9's *TextTheme helpers return material_ui.TextTheme, which
    // is not assignable to Flutter's ThemeData.textTheme. Apply Cairo per style.
    final baseText = ThemeData(useMaterial3: true).textTheme;
    TextStyle cairo(TextStyle? style, {FontWeight? weight, Color? color}) {
      return GoogleFonts.cairo(
        textStyle: style,
        fontWeight: weight ?? style?.fontWeight,
        color: color ?? style?.color,
      );
    }

    final textTheme = baseText
        .copyWith(
          displayLarge: cairo(
            baseText.displayLarge,
            color: AppColors.navy,
            weight: FontWeight.bold,
          ),
          displayMedium: cairo(
            baseText.displayMedium,
            color: AppColors.navy,
            weight: FontWeight.bold,
          ),
          displaySmall: cairo(
            baseText.displaySmall,
            color: AppColors.navy,
            weight: FontWeight.bold,
          ),
          headlineLarge: cairo(
            baseText.headlineLarge,
            color: AppColors.navy,
            weight: FontWeight.bold,
          ),
          headlineMedium: cairo(
            baseText.headlineMedium,
            color: AppColors.navy,
            weight: FontWeight.bold,
          ),
          headlineSmall: cairo(
            baseText.headlineSmall,
            color: AppColors.navy,
            weight: FontWeight.bold,
          ),
          titleLarge: cairo(
            baseText.titleLarge,
            color: AppColors.navy,
            weight: FontWeight.bold,
          ),
          titleMedium: cairo(
            baseText.titleMedium,
            color: AppColors.navy,
            weight: FontWeight.w700,
          ),
          titleSmall: cairo(
            baseText.titleSmall,
            color: AppColors.navy,
            weight: FontWeight.w700,
          ),
          bodyLarge: cairo(baseText.bodyLarge, color: AppColors.navy),
          bodyMedium: cairo(baseText.bodyMedium, color: AppColors.navy),
          bodySmall: cairo(
            baseText.bodySmall,
            color: AppColors.navy.withValues(alpha: 0.75),
          ),
          labelLarge: cairo(
            baseText.labelLarge,
            color: AppColors.navy,
            weight: FontWeight.w600,
          ),
        )
        .apply(bodyColor: AppColors.navy, displayColor: AppColors.navy);

    final controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(controlRadius),
    );
    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(cardRadius),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.scaffold,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeThroughPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeThroughPageTransitionsBuilder(),
          TargetPlatform.windows: FadeThroughPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeThroughPageTransitionsBuilder(),
          TargetPlatform.linux: FadeThroughPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.navy,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.deepBlue),
        actionsIconTheme: const IconThemeData(color: AppColors.deepBlue),
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 0,
        shape: cardShape,
        margin: EdgeInsets.zero,
        shadowColor: AppColors.deepBlue.withValues(alpha: 0.12),
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.paleBlue,
        floatingLabelStyle: const TextStyle(color: AppColors.midBlue),
        contentPadding: const EdgeInsetsDirectional.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: const BorderSide(color: AppColors.midBlue, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: const BorderSide(color: AppColors.deepBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.deepBlue,
          foregroundColor: AppColors.white,
          minimumSize: controlMinimumSize,
          elevation: 2,
          shadowColor: AppColors.deepBlue.withValues(alpha: 0.25),
          shape: controlShape,
          textStyle: textTheme.labelLarge?.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.deepBlue,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.midBlue.withValues(alpha: 0.45),
          disabledForegroundColor: AppColors.white,
          minimumSize: controlMinimumSize,
          elevation: 2,
          shadowColor: AppColors.deepBlue.withValues(alpha: 0.25),
          shape: controlShape,
          textStyle: textTheme.labelLarge?.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.deepBlue,
          minimumSize: controlMinimumSize,
          side: const BorderSide(color: AppColors.deepBlue, width: 1.5),
          shape: controlShape,
          textStyle: textTheme.labelLarge?.copyWith(
            color: AppColors.deepBlue,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.deepBlue,
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.white,
        indicatorColor: AppColors.paleBlue,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.deepBlue);
          }
          return IconThemeData(color: AppColors.navy.withValues(alpha: 0.55));
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelMedium?.copyWith(
            color: selected ? AppColors.deepBlue : AppColors.navy,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          );
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.paleBlue,
        selectedColor: AppColors.midBlue.withValues(alpha: 0.2),
        disabledColor: AppColors.paleBlue.withValues(alpha: 0.6),
        labelStyle: textTheme.labelLarge?.copyWith(color: AppColors.navy),
        secondaryLabelStyle: textTheme.labelLarge?.copyWith(
          color: AppColors.white,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide.none,
        ),
        side: BorderSide.none,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.navy,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(controlRadius),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.deepBlue,
        foregroundColor: AppColors.white,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.deepBlue,
        unselectedLabelColor: AppColors.navy.withValues(alpha: 0.55),
        indicatorColor: AppColors.deepBlue,
        dividerColor: AppColors.paleBlue,
        labelStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: textTheme.labelLarge,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.deepBlue,
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.paleBlue,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
