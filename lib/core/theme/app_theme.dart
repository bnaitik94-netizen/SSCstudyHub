import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_component_theme.dart';
import 'app_typography.dart';

/// Central theme architecture for SSC Study Hub.
/// Generates full Material 3 light and dark themes using semantic color tokens.
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
      dividerColor: AppColors.surfaceHighLight,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        titleTextStyle: textTheme.headlineSmall?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
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
        color: AppColors.surfaceLowDark,
        borderColor: AppColors.surfaceMidDark,
      ),
      filledButtonTheme: AppComponentTheme.filledButtonTheme(colorScheme),
      outlinedButtonTheme: AppComponentTheme.outlinedButtonTheme(colorScheme),
      textButtonTheme: AppComponentTheme.textButtonTheme(colorScheme),
      inputDecorationTheme: AppComponentTheme.inputDecorationTheme(
        fillColor: AppColors.surfaceLowDark,
        borderColor: AppColors.surfaceMidDark,
        colorScheme: colorScheme,
      ),
      chipTheme: AppComponentTheme.chipTheme(
        backgroundColor: AppColors.surfaceMidDark,
        borderColor: AppColors.surfaceHighDark,
        colorScheme: colorScheme,
      ),
      navigationBarTheme: AppComponentTheme.navigationBarTheme(colorScheme),
      dialogTheme: AppComponentTheme.dialogTheme(
        backgroundColor: AppColors.surfaceLowDark,
        borderColor: AppColors.surfaceMidDark,
      ),
      snackBarTheme: AppComponentTheme.snackBarTheme(colorScheme),
      bottomSheetTheme: AppComponentTheme.bottomSheetTheme(
        backgroundColor: AppColors.surfaceLowDark,
      ),
      dividerColor: AppColors.surfaceMidDark,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        titleTextStyle: textTheme.headlineSmall?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static ColorScheme _lightColorScheme() {
    return ColorScheme.fromSeed(
      seedColor: AppColors.seedColor,
      brightness: Brightness.light,
    ).copyWith(
      surface: AppColors.surfaceLowestLight,
      surfaceContainerLowest: AppColors.surfaceLowestLight,
      surfaceContainerLow: AppColors.surfaceLowLight,
      surfaceContainer: AppColors.surfaceMidLight,
      surfaceContainerHigh: AppColors.surfaceHighLight,
      surfaceContainerHighest: AppColors.surfaceHighestLight,
      onSurface: AppColors.textPrimaryLight,
      onSurfaceVariant: AppColors.textSecondaryLight,
      outline: AppColors.surfaceHighLight,
      outlineVariant: AppColors.surfaceMidLight,
      error: AppColors.error,
    );
  }

  static ColorScheme _darkColorScheme() {
    return ColorScheme.fromSeed(
      seedColor: AppColors.seedColor,
      brightness: Brightness.dark,
    ).copyWith(
      surface: AppColors.surfaceLowestDark,
      surfaceContainerLowest: AppColors.surfaceLowestDark,
      surfaceContainerLow: AppColors.surfaceLowDark,
      surfaceContainer: AppColors.surfaceMidDark,
      surfaceContainerHigh: AppColors.surfaceHighDark,
      surfaceContainerHighest: AppColors.surfaceHighestDark,
      onSurface: AppColors.textPrimaryDark,
      onSurfaceVariant: AppColors.textSecondaryDark,
      outline: AppColors.surfaceMidDark,
      outlineVariant: AppColors.surfaceHighDark,
      error: AppColors.error,
    );
  }
}
