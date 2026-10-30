import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Two-family typography system:
/// - Display/Headline: Geometric, confident display typeface (Plus Jakarta Sans / Cabinet aesthetic)
/// - Body/Label: Clean, readable neo-grotesque (Inter, 1.5 line-height base)
/// - Monospace: JetBrains Mono for metrics, code, timestamps
/// Strict Scale: Display(48) -> H1(32) -> H2(24) -> H3(18) -> Body(16) -> Caption(12) -> Label(11)
class AppTypography {
  // Base font builders
  static TextStyle displayFont({
    required double fontSize,
    required FontWeight fontWeight,
    double letterSpacing = -0.5,
    double height = 1.2,
    required Color color,
    bool useGoogleFonts = true,
  }) {
    if (useGoogleFonts) {
      return GoogleFonts.plusJakartaSans(
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        height: height,
        color: color,
      );
    }
    return TextStyle(
      fontFamily: 'PlusJakartaSans',
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      height: height,
      color: color,
    );
  }

  static TextStyle bodyFont({
    required double fontSize,
    required FontWeight fontWeight,
    double letterSpacing = 0.0,
    double height = 1.5,
    required Color color,
    bool useGoogleFonts = true,
  }) {
    if (useGoogleFonts) {
      return GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        height: height,
        color: color,
      );
    }
    return TextStyle(
      fontFamily: 'Inter',
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      height: height,
      color: color,
    );
  }

  static TextStyle monoFont({
    required double fontSize,
    required FontWeight fontWeight,
    double letterSpacing = 0.0,
    double height = 1.4,
    required Color color,
    bool useGoogleFonts = true,
  }) {
    if (useGoogleFonts) {
      return GoogleFonts.jetBrainsMono(
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        height: height,
        color: color,
      );
    }
    return TextStyle(
      fontFamily: 'Courier',
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      height: height,
      color: color,
    );
  }

  // Direct Token Accessors
  static TextStyle display(Color color, {bool useGoogleFonts = true}) =>
      displayFont(fontSize: 48, fontWeight: FontWeight.w800, letterSpacing: -1.0, color: color, useGoogleFonts: useGoogleFonts);

  static TextStyle h1(Color color, {bool useGoogleFonts = true}) =>
      displayFont(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: color, useGoogleFonts: useGoogleFonts);

  static TextStyle h2(Color color, {bool useGoogleFonts = true}) =>
      displayFont(fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.3, color: color, useGoogleFonts: useGoogleFonts);

  static TextStyle h3(Color color, {bool useGoogleFonts = true}) =>
      displayFont(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: -0.2, color: color, useGoogleFonts: useGoogleFonts);

  static TextStyle body(Color color, {bool useGoogleFonts = true, FontWeight weight = FontWeight.w400}) =>
      bodyFont(fontSize: 16, fontWeight: weight, letterSpacing: 0.1, color: color, useGoogleFonts: useGoogleFonts);

  static TextStyle caption(Color color, {bool useGoogleFonts = true, FontWeight weight = FontWeight.w500}) =>
      bodyFont(fontSize: 12, fontWeight: weight, letterSpacing: 0.2, height: 1.3, color: color, useGoogleFonts: useGoogleFonts);

  static TextStyle label(Color color, {bool useGoogleFonts = true, FontWeight weight = FontWeight.w600}) =>
      bodyFont(fontSize: 11, fontWeight: weight, letterSpacing: 0.3, height: 1.2, color: color, useGoogleFonts: useGoogleFonts);

  static TextStyle mono(Color color, {bool useGoogleFonts = true, double size = 13}) =>
      monoFont(fontSize: size, fontWeight: FontWeight.w500, color: color, useGoogleFonts: useGoogleFonts);

  // Full Material 3 TextTheme Generator
  static TextTheme createTextTheme(
    Color defaultTextColor, {
    bool useGoogleFonts = true,
  }) {
    return TextTheme(
      displayLarge: displayFont(
        fontSize: 48,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.0,
        color: defaultTextColor,
        useGoogleFonts: useGoogleFonts,
      ),
      displayMedium: displayFont(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: defaultTextColor,
        useGoogleFonts: useGoogleFonts,
      ),
      displaySmall: displayFont(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: defaultTextColor,
        useGoogleFonts: useGoogleFonts,
      ),
      headlineLarge: displayFont(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        color: defaultTextColor,
        useGoogleFonts: useGoogleFonts,
      ),
      headlineMedium: displayFont(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: defaultTextColor,
        useGoogleFonts: useGoogleFonts,
      ),
      headlineSmall: displayFont(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
        color: defaultTextColor,
        useGoogleFonts: useGoogleFonts,
      ),
      titleLarge: displayFont(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.0,
        color: defaultTextColor,
        useGoogleFonts: useGoogleFonts,
      ),
      titleMedium: bodyFont(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        color: defaultTextColor,
        useGoogleFonts: useGoogleFonts,
      ),
      titleSmall: bodyFont(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: defaultTextColor,
        useGoogleFonts: useGoogleFonts,
      ),
      bodyLarge: bodyFont(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.15,
        color: defaultTextColor,
        useGoogleFonts: useGoogleFonts,
      ),
      bodyMedium: bodyFont(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: defaultTextColor,
        useGoogleFonts: useGoogleFonts,
      ),
      bodySmall: bodyFont(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.3,
        color: defaultTextColor,
        useGoogleFonts: useGoogleFonts,
      ),
      labelLarge: bodyFont(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: defaultTextColor,
        useGoogleFonts: useGoogleFonts,
      ),
      labelMedium: bodyFont(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: defaultTextColor,
        useGoogleFonts: useGoogleFonts,
      ),
      labelSmall: bodyFont(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.3,
        color: defaultTextColor,
        useGoogleFonts: useGoogleFonts,
      ),
    );
  }
}
