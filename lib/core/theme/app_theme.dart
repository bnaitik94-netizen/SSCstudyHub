import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_component_theme.dart';
import 'app_typography.dart';

/// Central theme architecture for SSC Study Hub.
/// Engineered for Dark-First studio aesthetics (Linear/Vercel inspired).
/// Follows shadow-free tint elevations and WCAG AA contrast standards.
class AppTheme {
  static ThemeData light({bool useGoogleFonts = true}) {
    final colorScheme = _lightColorScheme();
    final textTheme = AppTypography.createTextTheme(
      colorScheme.onSurface,
      useGoogleFonts: useGoogleFonts,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: textTheme,
      cardTheme: AppComponentTheme.cardTheme(
        color: AppColors.surfaceLowLight,
        borderColor: AppColors.surfaceHighLight,
      ),
      filledButtonTheme: AppComponentTheme.filledButtonTheme(colorScheme),
      outlinedButtonTheme: AppComponentTheme.outlinedButtonTheme(colorScheme),
      textButtonTheme: AppComponentTheme.textButtonTheme(colorScheme),
      inputDecorationTheme: AppComponentTheme.inputDecorationTheme(
        fillColor: AppColors.surfaceLowLight,
        borderColor: AppColors.surfaceHighLight,
        colorScheme: colorScheme,
      ),
      chipTheme: AppComponentTheme.chipTheme(
        backgroundColor: AppColors.surfaceMidLight,
        borderColor: AppColors.surfaceHighLight,
        colorScheme: colorScheme,
      ),
      navigationBarTheme: AppComponentTheme.navigationBarTheme(colorScheme),
      dialogTheme: AppComponentTheme.dialogTheme(
        backgroundColor: AppColors.surfaceLowLight,
        borderColor: AppColors.surfaceHighLight,
      ),
      snackBarTheme: AppComponentTheme.snackBarTheme(colorScheme),
      bottomSheetTheme: AppComponentTheme.bottomSheetTheme(
        backgroundColor: AppColors.surfaceLowLight,
      ),
      dividerColor: AppColors.dividerLight,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        titleTextStyle: textTheme.headlineSmall?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  static ThemeData dark({bool useGoogleFonts = true}) {
    final colorScheme = _darkColorScheme();
    final textTheme = AppTypography.createTextTheme(
      colorScheme.onSurface,
      useGoogleFonts: useGoogleFonts,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: textTheme,
      cardTheme: AppComponentTheme.cardTheme(
        color: AppColors.surfaceDark,
        borderColor: AppColors.dividerDark,
      ),
      filledButtonTheme: AppComponentTheme.filledButtonTheme(colorScheme),
      outlinedButtonTheme: AppComponentTheme.outlinedButtonTheme(colorScheme),
      textButtonTheme: AppComponentTheme.textButtonTheme(colorScheme),
      inputDecorationTheme: AppComponentTheme.inputDecorationTheme(
        fillColor: AppColors.surfaceVariantDark,
        borderColor: AppColors.dividerDark,
        colorScheme: colorScheme,
      ),
      chipTheme: AppComponentTheme.chipTheme(
        backgroundColor: AppColors.surfaceVariantDark,
        borderColor: AppColors.dividerDark,
        colorScheme: colorScheme,
      ),
      navigationBarTheme: AppComponentTheme.navigationBarTheme(colorScheme),
      dialogTheme: AppComponentTheme.dialogTheme(
        backgroundColor: AppColors.surfaceDark,
        borderColor: AppColors.dividerDark,
      ),
      snackBarTheme: AppComponentTheme.snackBarTheme(colorScheme),
      bottomSheetTheme: AppComponentTheme.bottomSheetTheme(
        backgroundColor: AppColors.surfaceDark,
      ),
      dividerColor: AppColors.dividerDark,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        titleTextStyle: textTheme.headlineSmall?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  static ColorScheme _lightColorScheme() {
    return ColorScheme.fromSeed(
      seedColor: AppColors.primaryAccent,
      brightness: Brightness.light,
    ).copyWith(
      surface: AppColors.backgroundLight,
      surfaceContainerLowest: AppColors.backgroundLight,
      surfaceContainerLow: AppColors.surfaceLight,
      surfaceContainer: AppColors.surfaceVariantLight,
      surfaceContainerHigh: AppColors.surfaceHighLight,
      surfaceContainerHighest: AppColors.surfaceHighestLight,
      onSurface: AppColors.textPrimaryLight,
      onSurfaceVariant: AppColors.textSecondaryLight,
      outline: AppColors.surfaceHighLight,
      outlineVariant: AppColors.dividerLight,
      error: AppColors.error,
    );
  }

  static ColorScheme _darkColorScheme() {
    return ColorScheme.fromSeed(
      seedColor: AppColors.primaryAccent,
      brightness: Brightness.dark,
    ).copyWith(
      surface: AppColors.backgroundDark,
      surfaceContainerLowest: AppColors.backgroundDark,
      surfaceContainerLow: AppColors.surfaceDark,
      surfaceContainer: AppColors.surfaceVariantDark,
      surfaceContainerHigh: AppColors.surfaceHighDark,
      surfaceContainerHighest: AppColors.surfaceHighestDark,
      onSurface: AppColors.textPrimaryDark,
      onSurfaceVariant: AppColors.textSecondaryDark,
      outline: AppColors.surfaceVariantDark,
      outlineVariant: AppColors.dividerDark,
      error: AppColors.error,
    );
  }
}
