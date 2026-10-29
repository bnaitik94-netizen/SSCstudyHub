import 'package:flutter/material.dart';

/// 💎 NEO-STUDIO DESIGN SYSTEM (Ultra-Optimized for Low-End & High-End Devices)
/// Zero-lag, single GPU pass, high-contrast, professional modern education UI.
class AppColors {
  // ── Brand Identity & Accents ──────────────────────────────────────────────
  static const Color primary = Color(0xFF6366F1); // Electric Indigo
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4338CA);
  static const Color accent = Color(0xFF38BDF8); // Electric Cyan
  static const Color accentLight = Color(0xFF7DD3FC);
  static const Color accentDark = Color(0xFF0284C7);
  static const Color liveRed = Color(0xFFEF4444); // Radiant Crimson
  static const Color livePulse = Color(0xFFF43F5E);

  // ── Deep Modern Obsidian Slate Backgrounds (Battery & GPU Friendly) ───────
  static const Color backgroundTop = Color(0xFF090D16);
  static const Color backgroundMiddle = Color(0xFF0E1424);
  static const Color backgroundBottom = Color(0xFF060910);

  // Surface Card & Container Colors
  static const Color surfaceBase = Color(0xFF111827); // Slate 900
  static const Color surfaceCard = Color(0xFF141D32); // Refined Slate Navy
  static const Color surfaceCardElevated = Color(0xFF1B2642); // Elevated Interactive Card
  static const Color surfaceCardBorder = Color(0xFF223254); // High-Precision Crisp 1px Border
  static const Color surfaceSubtle = Color(0x1A38BDF8); // Subtle Cyan Glow Surface

  // Backward-compatible cosmic palette aliases
  static const Color cosmicBlueDeep = Color(0xFF0E1424);
  static const Color cosmicBlueVibrant = Color(0xFF1D4ED8);
  static const Color cosmicIndigo = Color(0xFF202654);
  static const Color cosmicPurpleDeep = Color(0xFF221644);
  static const Color cosmicPurpleVibrant = Color(0xFF8B5CF6);
  static const Color cosmicVioletMidnight = Color(0xFF18153A);
  static const Color cosmicRedDeep = Color(0xFF3A1518);
  static const Color cosmicRedVibrant = Color(0xFFEF4444);
  static const Color cosmicYellowDeep = Color(0xFF5A2A08);
  static const Color cosmicYellowVibrant = Color(0xFFFBBF24);

  // Glow accents
  static const Color glowBlue = Color(0xFF60A5FA);
  static const Color glowIndigo = Color(0xFF818CF8);
  static const Color glowCyan = Color(0xFF38BDF8);
  static const Color glowEmerald = Color(0xFF34D399);

  static const Color backgroundLight = Colors.transparent;
  static const Color backgroundDark = Colors.transparent;
  static const Color surfaceLight = Color(0x24FFFFFF);
  static const Color surfaceDark = Color(0xFF141D32);

  // ── High-Contrast Typography ──────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF8FAFC); // Slate 50 (Ultra crisp)
  static const Color textSecondary = Color(0xFF94A3B8); // Slate 400
  static const Color textMuted = Color(0xFF64748B); // Slate 500
  static const Color textDark = Color(0xFFF8FAFC);
  static const Color textLight = Color(0xFFF1F5F9);

  // Semantic Feedback Colors
  static const Color success = Color(0xFF10B981); // Emerald
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color error = Color(0xFFEF4444); // Rose Red
  static const Color info = Color(0xFF38BDF8); // Sky Blue

  // Chat & Classroom Tokens
  static const Color lockedChatBg = Color(0x66000000);
  static const Color privateChatBg = Color(0x2638BDF8);
  static const Color pinnedBg = Color(0xFF1A2642);
  static const Color pinnedBorder = Color(0x66F59E0B);
  static const Color pinnedText = Color(0xFFFBBF24);

  static final ValueNotifier<bool> isBackgroundAnimating =
      ValueNotifier<bool>(true);

  // ── Hardware-Accelerated Shadow System (Low GPU Cost) ──────────────────────
  static List<BoxShadow> softShadow([bool isDark = true]) => const [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 10,
          offset: Offset(0, 4),
        )
      ];

  // ── Optimized Component Decorations ───────────────────────────────────────

  /// Modern Studio Card (Crisp 1px border, high contrast, zero backdrop-filter lag)
  static BoxDecoration get liquidGlassCard => BoxDecoration(
        color: surfaceCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: surfaceCardBorder,
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      );

  /// Elevated Interactive Card (For Hero banners & Live tiles)
  static BoxDecoration get elevatedCard => BoxDecoration(
        color: surfaceCardElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF2C3E66),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      );

  /// Sleek Floating Bottom Navigation Capsule
  static BoxDecoration get liquidGlassTab => BoxDecoration(
        color: const Color(0xF50F172A), // Slate 900 semi-opaque
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFF253452),
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x59000000),
            blurRadius: 20,
            offset: Offset(0, 8),
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
            Color(0xFF0284C7), // Deep Ocean Cyan
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0x66A5B4FC),
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4D6366F1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      );

  /// Clean Glass Style (Legacy compatibility)
  static BoxDecoration get premiumGlass => liquidGlassCard;
  static BoxDecoration get bottomNavGlassDark => liquidGlassTab;
}
