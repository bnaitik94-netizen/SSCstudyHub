import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Master Bottom Sheet and Modal System:
/// - DraggableScrollableSheet with 4x32px pill handle indicator.
/// - 60% black backdrop + frosted blur filter.
/// - Slide-up 300ms easeOutCubic entrance.
/// - Full-screen modal with fade + scale (0.95 -> 1.0) entrance.
class AppBottomSheet {
  /// Show studio-grade bottom sheet with DraggableScrollableSheet
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget Function(BuildContext context, ScrollController scrollController) builder,
    String? title,
    bool isDismissible = true,
    double initialChildSize = 0.6,
    double minChildSize = 0.3,
    double maxChildSize = 0.95,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final sheetBg = isDark
        ? AppColors.surfaceDark
        : AppColors.surfaceLight;

    final handleColor = isDark
        ? AppColors.surfaceVariantDark
        : AppColors.surfaceHighLight;

    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: isDismissible,
      useSafeArea: true,
      barrierColor: Colors.black.withValues(alpha: 0.60), // 60% black backdrop
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Blur(10)
          child: Container(
            decoration: BoxDecoration(
              color: sheetBg,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSpacing.radiusXl),
              ),
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.08),
                  width: 1,
                ),
              ),
            ),
            child: DraggableScrollableSheet(
              initialChildSize: initialChildSize,
              minChildSize: minChildSize,
              maxChildSize: maxChildSize,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Pill handle indicator: 4x32px
                    Center(
                      child: Container(
                        width: 32,
                        height: 4,
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: handleColor,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                        ),
                      ),
                    ),
                    if (title != null) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.screenHorizontal,
                          vertical: AppSpacing.sm,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 20),
                              tooltip: 'Close',
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                      ),
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                      ),
                    ],
                    Expanded(
                      child: builder(context, scrollController),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  /// Show Full-Screen Modal with fade + scale(0.95 -> 1.0) transition
  static Future<T?> showFullScreenModal<T>({
    required BuildContext context,
    required Widget child,
    bool barrierDismissible = true,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: 'Modal',
      barrierColor: Colors.black.withValues(alpha: 0.65),
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (context, anim1, anim2, modalChild) {
        final curvedValue = Curves.easeOutCubic.transform(anim1.value);
        return Transform.scale(
          scale: 0.95 + (0.05 * curvedValue),
          child: Opacity(
            opacity: anim1.value,
            child: modalChild,
          ),
        );
      },
      pageBuilder: (context, anim1, anim2) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: SafeArea(
            child: Dialog(
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.surfaceDark
                  : AppColors.surfaceLight,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                side: BorderSide(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.dividerDark
                      : AppColors.dividerLight,
                ),
              ),
              insetPadding: const EdgeInsets.all(AppSpacing.lg),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
