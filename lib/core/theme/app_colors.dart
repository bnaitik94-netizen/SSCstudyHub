import 'package:flutter/material.dart';

/// Semantic color tokens for SSC Study Hub.
/// Engineered for Dark-First studio aesthetics (Linear/Vercel inspired).
/// Follows strict WCAG AA contrast standards with tint-based MD3 elevations.
class AppColors {
  // Brand Accents
  static const Color primaryAccent = Color(0xFF6366F1); // Electric Indigo (#6366F1)
  static const Color seedColor = primaryAccent;
  static const Color secondaryAccent = Color(0xFF06B6D4); // Electric Cyan (shifted 30% saturation complement)
  static const Color secondarySeed = secondaryAccent;
  static const Color onPrimary = Color(0xFFFFFFFF);

  // Dark Mode Tokens (Primary Theme)
  static const Color backgroundDark = Color(0xFF0A0A0F);     // Near-void, not pure black
  static const Color surfaceDark = Color(0xFF13131A);        // Card surfaces
  static const Color surfaceVariantDark = Color(0xFF1C1C28); // Elevated panels
  static const Color textPrimaryDark = Color(0xFFF0F0F5);    // High-contrast primary text
  static const Color textSecondaryDark = Color(0xFF8A8A9A);  // Subtitles & captions
  static const Color textDisabledDark = Color(0xFF525266);   // Disabled text
  static const Color textInverseDark = Color(0xFF0A0A0F);
  static const Color dividerDark = Color(0x0FFFFFFF);        // rgba(255, 255, 255, 0.06)

  // Surface Hierarchy Aliases (Dark)
  static const Color surfaceLowestDark = backgroundDark;
  static const Color surfaceLowDark = surfaceDark;
  static const Color surfaceMidDark = surfaceVariantDark;
  static const Color surfaceHighDark = Color(0xFF262636);     // Level 2 elevated
  static const Color surfaceHighestDark = Color(0xFF2E2E42);  // Level 3 modal / sheet

  // Light Mode Tokens (Adaptive Fallback)
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFF1F5F9);
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textDisabledLight = Color(0xFF94A3B8);
  static const Color textInverseLight = Color(0xFFF8FAFC);
  static const Color dividerLight = Color(0x0F000000);        // rgba(0, 0, 0, 0.06)

  // Surface Hierarchy Aliases (Light)
  static const Color surfaceLowestLight = backgroundLight;
  static const Color surfaceLowLight = surfaceLight;
  static const Color surfaceMidLight = surfaceVariantLight;
  static const Color surfaceHighLight = Color(0xFFE2E8F0);
  static const Color surfaceHighestLight = Color(0xFFCBD5E1);

  // Functional Colors (WCAG AA Compliant)
  static const Color error = Color(0xFFFF4D6A);              // Vibrant Studio Red
  static const Color success = Color(0xFF2ECC87);            // Vibrant Studio Emerald
  static const Color warning = Color(0xFFF59E0B);            // Studio Amber
  static const Color info = Color(0xFF06B6D4);               // Studio Cyan

  // Badge & Chip Surfaces - Dark
  static const Color successSurfaceDark = Color(0xFF093721);
  static const Color warningSurfaceDark = Color(0xFF3D2104);
  static const Color errorSurfaceDark = Color(0xFF3F0F18);
  static const Color infoSurfaceDark = Color(0xFF082F3B);
  static const Color neutralSurfaceDark = Color(0xFF1C1C28);

  // Badge & Chip Surfaces - Light
  static const Color successSurfaceLight = Color(0xFFECFDF5);
  static const Color warningSurfaceLight = Color(0xFFFFFBEB);
  static const Color errorSurfaceLight = Color(0xFFFEF2F2);
  static const Color infoSurfaceLight = Color(0xFFEFF6FF);
  static const Color neutralSurfaceLight = Color(0xFFF1F5F9);

  // Elevation Tint Overlays (MD3 standard without GPU shadow cost)
  static const double elevationLevel0 = 0.00; // Background (0%)
  static const double elevationLevel1 = 0.05; // Cards (+5% white)
  static const double elevationLevel2 = 0.08; // Panels (+8% white)
  static const double elevationLevel3 = 0.11; // Modals / Sheets (+11% white)

  /// Returns surface with MD3 white-overlay tint for elevation
  static Color elevatedSurface(Color baseSurface, double tintPercent) {
    if (tintPercent <= 0) return baseSurface;
    return Color.alphaBlend(Colors.white.withValues(alpha: tintPercent), baseSurface);
  }
}
