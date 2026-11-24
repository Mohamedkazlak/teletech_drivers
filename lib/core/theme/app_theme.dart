import 'package:flutter/material.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/core/theme/app_page_transitions.dart';
import 'package:teletech_drivers/core/theme/app_typography.dart';

/// Light Material 3 theme for TeleCars ("Ring & Route", see DESIGN.md).
abstract final class AppTheme {
  static const double cardRadius = 16;
  static const double controlRadius = 14;
  static const double pillRadius = 999;

  static const double controlHeight = 52;

  /// Finite width so a button can live in a [Row] or dialog action bar.
  /// [Size.fromHeight] is infinite width and crashes those layouts.
  static const Size controlMinimumSize = Size(64, controlHeight);

  /// Soft, offset shadow for floating chrome only (bar, hero surface).
  static List<BoxShadow> floatingShadow({double opacity = 0.14}) => [
    BoxShadow(
      color: AppColors.navy.withValues(alpha: opacity),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static ThemeData get light {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.deepBlue,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.deepBlue,
          onPrimary: AppColors.white,
          primaryContainer: AppColors.paleBlue,
          onPrimaryContainer: AppColors.navy,
          secondary: AppColors.signal,
          tertiary: AppColors.midBlue,
          surface: AppColors.white,
          onSurface: AppColors.navy,
          onSurfaceVariant: AppColors.inkMuted,
          surfaceContainerHighest: AppColors.paleBlue,
          outline: AppColors.line,
          outlineVariant: AppColors.line,
          shadow: AppColors.navy,
          error: AppColors.error,
        );

    final baseText = ThemeData(useMaterial3: true).textTheme;
    TextStyle brand(TextStyle? style, {FontWeight? weight, Color? color}) {
      return AppTypography.apply(style, weight: weight, color: color);
    }

    final textTheme = baseText
        .copyWith(
          displayLarge: brand(baseText.displayLarge, weight: FontWeight.w600),
          displayMedium: brand(baseText.displayMedium, weight: FontWeight.w600),
          displaySmall: brand(baseText.displaySmall, weight: FontWeight.w600),
          headlineLarge: brand(
            baseText.headlineLarge,
            weight: FontWeight.w600,
          ).copyWith(letterSpacing: -0.6),
          headlineMedium: brand(
            baseText.headlineMedium,
            weight: FontWeight.w600,
          ).copyWith(letterSpacing: -0.5),
          headlineSmall: brand(
            baseText.headlineSmall,
            weight: FontWeight.w600,
          ).copyWith(letterSpacing: -0.4),
          titleLarge: brand(
            baseText.titleLarge,
            weight: FontWeight.w600,
          ).copyWith(letterSpacing: -0.2),
          titleMedium: brand(baseText.titleMedium, weight: FontWeight.w600),
          titleSmall: brand(baseText.titleSmall, weight: FontWeight.w600),
          bodyLarge: brand(baseText.bodyLarge),
          bodyMedium: brand(baseText.bodyMedium),
          bodySmall: brand(baseText.bodySmall, color: AppColors.inkMuted),
          labelLarge: brand(baseText.labelLarge, weight: FontWeight.w600),
          labelMedium: brand(baseText.labelMedium, weight: FontWeight.w500),
          labelSmall: brand(baseText.labelSmall, weight: FontWeight.w500),
        )
        .apply(bodyColor: AppColors.navy, displayColor: AppColors.navy);

    final controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(controlRadius),
    );
    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(cardRadius),
      side: const BorderSide(color: AppColors.line),
    );
    final buttonText = textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.scaffold,
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: AppPageTransitionsBuilder(),
          TargetPlatform.iOS: AppPageTransitionsBuilder(),
          TargetPlatform.windows: AppPageTransitionsBuilder(),
          TargetPlatform.macOS: AppPageTransitionsBuilder(),
          TargetPlatform.linux: AppPageTransitionsBuilder(),
        },
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.deepBlue,
        selectionColor: AppColors.signal.withValues(alpha: 0.24),
        selectionHandleColor: AppColors.deepBlue,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.scaffold,
        foregroundColor: AppColors.navy,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: Colors.transparent,
        shadowColor: AppColors.line,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.navy, size: 22),
        actionsIconTheme: const IconThemeData(color: AppColors.navy, size: 22),
        titleTextStyle: textTheme.titleLarge,
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.navy,
          minimumSize: const Size(44, 44),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 0,
        shape: cardShape,
        margin: EdgeInsets.zero,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.inkMuted,
        titleTextStyle: textTheme.titleSmall,
        subtitleTextStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.inkMuted,
        ),
        contentPadding: const EdgeInsetsDirectional.symmetric(horizontal: 16),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        labelStyle: textTheme.bodyLarge?.copyWith(color: AppColors.inkMuted),
        floatingLabelStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.deepBlue,
          fontWeight: FontWeight.w600,
        ),
        prefixIconColor: WidgetStateColor.resolveWith((states) {
          return states.contains(WidgetState.focused)
              ? AppColors.deepBlue
              : AppColors.inkMuted;
        }),
        contentPadding: const EdgeInsetsDirectional.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: const BorderSide(color: AppColors.line),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: BorderSide(color: AppColors.line.withValues(alpha: 0.6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: const BorderSide(color: AppColors.deepBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(controlRadius),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.deepBlue,
          foregroundColor: AppColors.white,
          minimumSize: controlMinimumSize,
          elevation: 0,
          shape: controlShape,
          textStyle: buttonText,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.deepBlue,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.line,
          disabledForegroundColor: AppColors.inkMuted,
          minimumSize: controlMinimumSize,
          elevation: 0,
          shape: controlShape,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.deepBlue,
          backgroundColor: AppColors.white,
          minimumSize: controlMinimumSize,
          side: const BorderSide(color: AppColors.line, width: 1.2),
          shape: controlShape,
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.deepBlue,
          minimumSize: const Size(48, 44),
          shape: controlShape,
          textStyle: buttonText,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.white,
        indicatorColor: AppColors.paleBlue,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.deepBlue);
          }
          return const IconThemeData(color: AppColors.inkMuted);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelMedium?.copyWith(
            color: selected ? AppColors.deepBlue : AppColors.inkMuted,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          );
        }),
      ),
      chipTheme: ChipThemeData(
        color: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) {
            return AppColors.paleBlue.withValues(alpha: 0.6);
          }
          if (states.contains(WidgetState.selected)) return AppColors.navy;
          return AppColors.white;
        }),
        showCheckmark: false,
        labelStyle: textTheme.labelLarge?.copyWith(
          color: WidgetStateColor.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? AppColors.white
                : AppColors.navy;
          }),
        ),
        secondaryLabelStyle: textTheme.labelLarge?.copyWith(
          color: AppColors.white,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        shape: const StadiumBorder(side: BorderSide(color: AppColors.line)),
        side: const BorderSide(color: AppColors.line),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.inkMuted,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        dragHandleColor: AppColors.line,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.navy,
        elevation: 0,
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.white,
        ),
        actionTextColor: AppColors.lightBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(controlRadius),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.deepBlue,
        foregroundColor: AppColors.white,
        elevation: 2,
        highlightElevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.deepBlue,
        unselectedLabelColor: AppColors.inkMuted,
        indicatorColor: AppColors.deepBlue,
        indicatorSize: TabBarIndicatorSize.label,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: AppColors.deepBlue, width: 3),
          borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
        ),
        splashFactory: NoSplash.splashFactory,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        dividerColor: AppColors.line,
        labelStyle: textTheme.labelLarge,
        unselectedLabelStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.deepBlue,
        linearTrackColor: AppColors.paleBlue,
        circularTrackColor: Colors.transparent,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return AppColors.line;
          return AppColors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return states.contains(WidgetState.disabled)
                ? AppColors.lightBlue
                : AppColors.deepBlue;
          }
          return AppColors.line;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.line,
        thickness: 1,
        space: 1,
      ),
      badgeTheme: BadgeThemeData(
        backgroundColor: AppColors.error,
        textColor: AppColors.white,
        textStyle: AppTypography.tabular(textTheme.labelSmall),
      ),
    );
  }
}
