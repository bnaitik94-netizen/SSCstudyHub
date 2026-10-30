import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'app_button.dart';

/// Master Empty State:
/// - Supports Lottie animation asset or glowing gradient capsule.
/// - Clear headline + descriptive subtext.
/// - Primary CTA button for actionable recovery.
/// - Zero raw "No data found" text.
class AppEmptyState extends StatelessWidget {
  final IconData? icon;
  final String? lottieAsset;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppEmptyState({
    super.key,
    this.icon,
    this.lottieAsset,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Widget visual;
    if (lottieAsset != null && lottieAsset!.isNotEmpty) {
      visual = SizedBox(
        width: 140,
        height: 140,
        child: Lottie.asset(
          lottieAsset!,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => _buildIconCapsule(isDark),
        ),
      );
    } else {
      visual = _buildIconCapsule(isDark);
    }

    return RepaintBoundary(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              visual,
              const SizedBox(height: AppSpacing.lg),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.xs),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 280),
                  child: Text(
                    subtitle!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: AppSpacing.lg),
                AppButton.primaryCta(
                  label: actionLabel!,
                  onPressed: onAction,
                  isFullWidth: false,
                  height: 48,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconCapsule(bool isDark) {
    final displayIcon = icon ?? Icons.inbox_outlined;
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceMidLight,
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryAccent.withValues(alpha: isDark ? 0.15 : 0.08),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Icon(
          displayIcon,
          size: 32,
          color: AppColors.primaryAccent,
        ),
      ),
    );
  }
}
