/// Consistent 4pt base grid spacing and corner radius system for SSC Study Hub.
/// Merges Linear/Vercel precision with Material 3 tint elevations.
class AppSpacing {
  // 4pt Base Grid
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;

  // Intermediate utility spacing
  static const double spacing12 = 12.0;
  static const double spacing20 = 20.0;

  // Layout Constants
  static const double screenHorizontal = 16.0;
  static const double screenVertical = 16.0;
  static const double sectionGap = 24.0;
  static const double cardPadding = 16.0;
  static const double listItemGap = 8.0;

  // Border Radii (M3 & Studio standards)
  static const double radiusNone = 0.0;
  static const double radiusSm = 8.0;     // Inputs, sub-chips
  static const double radiusMd = 12.0;    // Small cards, menus
  static const double radiusLg = 16.0;    // Standard cards
  static const double radiusXl = 24.0;    // Modals, bottom sheets
  static const double radiusPill = 999.0; // Chips, pills, circular avatars
  static const double radiusFull = 999.0; // Alias

  // Elevation Tint Levels (Shadow-free MD3 standard)
  static const double elevationLevel0 = 0.00; // Background
  static const double elevationLevel1 = 0.05; // +5% white overlay (Cards)
  static const double elevationLevel2 = 0.08; // +8% white overlay (Panels)
  static const double elevationLevel3 = 0.11; // +11% white overlay (Modals, Sheets)
}
