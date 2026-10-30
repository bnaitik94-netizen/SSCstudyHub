import 'package:flutter/material.dart';

/// Semantic color tokens for SSC Study Hub.
/// All colors derive from Material 3 tonal palettes and semantic design tokens.
/// No raw hex values should exist outside this file.
class AppColors {
  // Brand Seed
  static const Color seedColor = Color(0xFF4F46E5); // Modern Indigo
  static const Color secondarySeed = Color(0xFF0EA5E9); // Ocean Cyan

  // Light Surfaces (Slate scale)
  static const Color surfaceLowestLight = Color(0xFFF8FAFC);   // Page background
  static const Color surfaceLowLight = Color(0xFFFFFFFF);      // Card background
  static const Color surfaceMidLight = Color(0xFFF1F5F9);      // Input background / borders
  static const Color surfaceHighLight = Color(0xFFE2E8F0);     // Elevated cards
  static const Color surfaceHighestLight = Color(0xFFCBD5E1);  // Modal / bottom sheet

  // Dark Surfaces (Neutral Very Dark ~#0F1117, never pure black #000000)
  static const Color surfaceLowestDark = Color(0xFF0F1117);    // Page background
  static const Color surfaceLowDark = Color(0xFF161922);       // Card background
  static const Color surfaceMidDark = Color(0xFF222734);       // Input background / borders
  static const Color surfaceHighDark = Color(0xFF2D3344);      // Elevated cards
  static const Color surfaceHighestDark = Color(0xFF384055);   // Modal / bottom sheet

  // Text Hierarchy - Light
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B);
  static const Color textDisabledLight = Color(0xFF94A3B8);
  static const Color textInverseLight = Color(0xFFF8FAFC);

  // Text Hierarchy - Dark
  static const Color textPrimaryDark = Color(0xFFF1F5F9);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textDisabledDark = Color(0xFF64748B);
  static const Color textInverseDark = Color(0xFF0F172A);

  // Functional Colors (WCAG AA Compliant)
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Badge & Chip Surfaces - Light
  static const Color successSurfaceLight = Color(0xFFECFDF5);
  static const Color warningSurfaceLight = Color(0xFFFFFBEB);
  static const Color errorSurfaceLight = Color(0xFFFEF2F2);
  static const Color infoSurfaceLight = Color(0xFFEFF6FF);

  // Badge & Chip Surfaces - Dark
  static const Color successSurfaceDark = Color(0xFF064E3B);
  static const Color warningSurfaceDark = Color(0xFF78350F);
  static const Color errorSurfaceDark = Color(0xFF7F1D1D);
  static const Color infoSurfaceDark = Color(0xFF1E3A8A);

  // Neutral Badge Surfaces
  static const Color neutralSurfaceLight = Color(0xFFF1F5F9);
  static const Color neutralSurfaceDark = Color(0xFF222734);
}
