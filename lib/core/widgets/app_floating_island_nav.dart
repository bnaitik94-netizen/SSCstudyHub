import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Navigation destination data for [AppFloatingIslandNav].
class AppNavDestination {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool isBadgeVisible;
  final String? badgeText;

  const AppNavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    this.isBadgeVisible = false,
    this.badgeText,
  });
}

/// Floating Island-style Navigation Bar inspired by iOS Dynamic Island & Studio apps.
/// Features frosted glassmorphism backdrop blur (sigma 20), animated item scaling,
/// haptic tactile clicks, and full safe-area adaptation.
class AppFloatingIslandNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<AppNavDestination> destinations;

  const AppFloatingIslandNav({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final capsuleBg = isDark
        ? AppColors.surfaceDark.withValues(alpha: 0.82)
        : AppColors.surfaceLight.withValues(alpha: 0.88);

    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.black.withValues(alpha: 0.08);

    return RepaintBoundary(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.screenHorizontal,
          0,
          AppSpacing.screenHorizontal,
          bottomPadding > 0 ? bottomPadding : AppSpacing.md,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: capsuleBg,
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                border: Border.all(color: borderColor, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: List.generate(destinations.length, (index) {
                  final item = destinations[index];
                  final isSelected = selectedIndex == index;

                  return Expanded(
                    child: _NavItem(
                      destination: item,
                      isSelected: isSelected,
                      onTap: () {
                        if (!isSelected) {
                          HapticFeedback.lightImpact();
                          onDestinationSelected(index);
                        }
                      },
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final AppNavDestination destination;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.destination,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const activeColor = AppColors.primaryAccent;
    final inactiveColor = theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: activeColor.withValues(alpha: 0.12),
        highlightColor: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        child: Semantics(
          label: destination.label,
          selected: isSelected,
          button: true,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? activeColor.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      AnimatedScale(
                        scale: isSelected ? 1.15 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        child: Icon(
                          isSelected ? destination.selectedIcon : destination.icon,
                          size: 22,
                          color: isSelected ? activeColor : inactiveColor,
                        ),
                      ),
                      if (destination.isBadgeVisible)
                        Positioned(
                          top: -3,
                          right: -5,
                          child: destination.badgeText != null
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.error,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    destination.badgeText!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.error,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? activeColor : inactiveColor,
                      letterSpacing: 0.1,
                    ),
                    child: Text(
                      destination.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
