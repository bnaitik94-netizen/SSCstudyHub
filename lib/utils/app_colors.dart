import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF6366F1);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4338CA);
  static const Color accent = Color(0xFF38BDF8);
  static const Color liveRed = Color(0xFFFF2A4B);

  // Cosmic Background Colors (Modern Lightened Luminous Slate/Twilight)
  static const Color cosmicBlueDeep = Color(0xFF0F1E36);
  static const Color cosmicBlueVibrant = Color(0xFF1D4ED8);
  static const Color cosmicIndigo = Color(0xFF2A2868);
  static const Color cosmicPurpleDeep = Color(0xFF2E1C5B);
  static const Color cosmicPurpleVibrant = Color(0xFF8B5CF6);
  static const Color cosmicVioletMidnight = Color(0xFF1E1B4B);

  static const Color cosmicRedDeep = Color(0xFF451A1A);
  static const Color cosmicRedVibrant = Color(0xFFEF4444);
  static const Color cosmicYellowDeep = Color(0xFF78350F);
  static const Color cosmicYellowVibrant = Color(0xFFFBBF24);

  // Modern Ultra-Professional Slate Background
  static const Color backgroundTop = Color(0xFF0B1120);
  static const Color backgroundMiddle = Color(0xFF0F172A);
  static const Color backgroundBottom = Color(0xFF090D16);
  static const Color glowBlue = Color(0xFF60A5FA);
  static const Color glowIndigo = Color(0xFF818CF8);
  static const Color glowCyan = Color(0xFF38BDF8);
  static const Color glowEmerald = Color(0xFF34D399);

  static const Color backgroundLight = Colors.transparent;
  static const Color backgroundDark = Colors.transparent;
  static const Color surfaceLight = Color(0x29FFFFFF);
  static const Color surfaceDark = Color(0x1FFFFFFF);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFA5B4FC);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textDark = Color(0xFFFFFFFF);
  static const Color textLight = Color(0xFFF1F5F9);

  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  static const Color lockedChatBg = Color(0x33000000);
  static const Color privateChatBg = Color(0x33FFFFFF);
  static const Color pinnedBg = Color(0x33000000);
  static const Color pinnedBorder = Color(0x4DFFFFFF);
  static const Color pinnedText = Color(0xFFF5AF19);

  static final ValueNotifier<bool> isBackgroundAnimating =
      ValueNotifier<bool>(true);

  static List<BoxShadow> softShadow([bool isDark = true]) => [
        BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6))
      ];

  // 🚀 LIGHT GLASS (For Home Screen Cards)
  static BoxDecoration get premiumGlass => BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x38FFFFFF), Color(0x1EFFFFFF)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x59FFFFFF), width: 1.2),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 18,
              offset: const Offset(0, 8))
        ],
      );

  // 🚀 DARK IPHONE GLASS (For Bottom Tab Bar)
  static BoxDecoration get bottomNavGlassDark => BoxDecoration(
        color: const Color(0xB31E293B),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0x59FFFFFF), width: 1.0),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.30),
              blurRadius: 24,
              offset: const Offset(0, 8))
        ],
      );

  // 💎 PREMIUM LIQUID GLASS DESIGN SYSTEM 💎
  
  /// High-Performance Sleek Tab Capsule (Zero Lag)
  static BoxDecoration get liquidGlassTab => BoxDecoration(
        color: const Color(0xF2162544),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(
          color: const Color(0x40FFFFFF),
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      );

  /// Smooth Pill for Selected Tab Indicator
  static BoxDecoration get liquidPill => BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6366F1), // Electric Indigo
            Color(0xFF38BDF8), // Vivid Cyan
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0x66FFFFFF),
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4038BDF8),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      );

  /// Ultra-Efficient Clean Card (Fast 120 FPS Rendering)
  static BoxDecoration get liquidGlassCard => BoxDecoration(
        color: const Color(0xFF1E2D4A),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0x2EFFFFFF),
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      );
}
