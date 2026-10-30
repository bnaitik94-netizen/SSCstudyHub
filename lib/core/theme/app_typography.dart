import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Complete Material 3 typography system built on Google Fonts Inter.
/// Max 2 body weights (400 regular, 500 medium) and display/bold (700 bold).
class AppTypography {
  static TextStyle _style({
    required double fontSize,
    required FontWeight fontWeight,
    required double letterSpacing,
    required Color color,
    bool useGoogleFonts = true,
  }) {
    if (useGoogleFonts) {
      return GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        color: color,
      );
    }
    return TextStyle(
      fontFamily: 'Inter',
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      color: color,
    );
  }

  static TextTheme createTextTheme(
    Color defaultTextColor, {
    bool useGoogleFonts = true,
  }) {
    return TextTheme(
      displayLarge: _style(
        fontSize: 57,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
        color: defaultTextColor,
        useGoogleFonts: useGoogleFonts,
      ),
      displayMedium: _style(
        fontSize: 45,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        color: defaultTextColor,
        useGoogleFonts: useGoogleFonts,
      ),
      displaySmall: _style(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        color: defaultTextColor,
        useGoogleFonts: useGoogleFonts,
      ),
      headlineLarge: _style(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        color: defaultTextColor,
        useGoogleFonts: useGoogleFonts,
      ),
      headlineMedium: _style(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        color: defaultTextColor,
        useGoogleFonts: useGoogleFonts,
      ),
      headlineSmall: _style(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: defaultTextColor,
        useGoogleFonts: useGoogleFonts,
      ),
      titleLarge: _style(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: defaultTextColor,
        useGoogleFonts: useGoogleFonts,
      ),
      titleMedium: _style(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        color: defaultTextColor,
        useGoogleFonts: useGoogleFonts,
      ),
      titleSmall: _style(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: defaultTextColor,
        useGoogleFonts: useGoogleFonts,
      ),
      bodyLarge: _style(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        color: defaultTextColor,
        useGoogleFonts: useGoogleFonts,
      ),
      bodyMedium: _style(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: defaultTextColor,
        useGoogleFonts: useGoogleFonts,
      ),
      bodySmall: _style(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: defaultTextColor,
        useGoogleFonts: useGoogleFonts,
      ),
      labelLarge: _style(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: defaultTextColor,
        useGoogleFonts: useGoogleFonts,
      ),
      labelMedium: _style(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: defaultTextColor,
        useGoogleFonts: useGoogleFonts,
      ),
      labelSmall: _style(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: defaultTextColor,
        useGoogleFonts: useGoogleFonts,
      ),
    );
  }
}
