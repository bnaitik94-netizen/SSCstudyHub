import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

enum AppBadgeVariant { success, warning, error, info, neutral }

/// Accessible, semantic pill badge with contrast-checked colors.
class AppBadge extends StatelessWidget {
  final String label;
  final AppBadgeVariant variant;
  final Widget? icon;

  const AppBadge({
    super.key,
    required this.label,
    this.variant = AppBadgeVariant.neutral,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg;
    Color fg;

    switch (variant) {
      case AppBadgeVariant.success:
        bg = isDark ? AppColors.successSurfaceDark : AppColors.successSurfaceLight;
        fg = isDark ? const Color(0xFF6EE7B7) : const Color(0xFF065F46);
        break;
      case AppBadgeVariant.warning:
        bg = isDark ? AppColors.warningSurfaceDark : AppColors.warningSurfaceLight;
        fg = isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E);
        break;
      case AppBadgeVariant.error:
        bg = isDark ? AppColors.errorSurfaceDark : AppColors.errorSurfaceLight;
        fg = isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B);
        break;
      case AppBadgeVariant.info:
        bg = isDark ? AppColors.infoSurfaceDark : AppColors.infoSurfaceLight;
        fg = isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E40AF);
        break;
      case AppBadgeVariant.neutral:
        bg = isDark ? AppColors.neutralSurfaceDark : AppColors.neutralSurfaceLight;
        fg = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            IconTheme(
              data: IconThemeData(size: 12, color: fg),
              child: icon!,
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
