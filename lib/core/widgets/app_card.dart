import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

enum _CardVariant { standard, primaryGradient, dataGlass, listItem }

/// Master Card System inspired by Linear and Vercel design systems.
/// Supports standard cards, primary gradient border cards, data glass cards,
/// and left-accented list item cards. All with custom InkWell splash overrides.
class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Color? borderColor;
  final double? borderRadius;
  final _CardVariant _variant;

  // List Item Specific Props
  final Widget? leading;
  final Widget? trailing;
  final Color? accentBarColor;

  /// Standard clean surface card
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.color,
    this.borderColor,
    this.borderRadius,
  })  : _variant = _CardVariant.standard,
        leading = null,
        trailing = null,
        accentBarColor = null;

  /// Primary card with 2px accent gradient border
  const AppCard.primary({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.color,
    this.borderRadius,
  })  : _variant = _CardVariant.primaryGradient,
        borderColor = null,
        leading = null,
        trailing = null,
        accentBarColor = null;

  /// Data card with glassmorphism surface tint
  const AppCard.data({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.color,
    this.borderRadius,
  })  : _variant = _CardVariant.dataGlass,
        borderColor = null,
        leading = null,
        trailing = null,
        accentBarColor = null;

  /// List item card with left accent bar, leading icon, and trailing chevron
  const AppCard.listItem({
    super.key,
    required this.child,
    this.onTap,
    this.leading,
    this.trailing,
    this.accentBarColor,
    this.padding,
    this.margin,
    this.color,
    this.borderRadius,
  })  : _variant = _CardVariant.listItem,
        borderColor = null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final radius = BorderRadius.circular(borderRadius ?? AppSpacing.radiusLg);

    Widget innerContent;

    if (_variant == _CardVariant.listItem) {
      innerContent = Padding(
        padding: padding ?? const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 3.5,
              height: 36,
              decoration: BoxDecoration(
                color: accentBarColor ?? AppColors.primaryAccent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            if (leading != null) ...[
              leading!,
              const SizedBox(width: AppSpacing.md),
            ],
            Expanded(child: child),
            trailing ??
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
          ],
        ),
      );
    } else {
      innerContent = Padding(
        padding: padding ?? const EdgeInsets.all(AppSpacing.cardPadding),
        child: child,
      );
    }

    Widget cardBody;

    if (_variant == _CardVariant.primaryGradient) {
      // 2px gradient border (accent -> transparent)
      cardBody = Container(
        margin: margin,
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryAccent,
              AppColors.secondaryAccent.withValues(alpha: 0.3),
              Colors.transparent,
            ],
          ),
        ),
        padding: const EdgeInsets.all(1.8), // 2px gradient border width
        child: Container(
          decoration: BoxDecoration(
            color: color ?? (isDark ? AppColors.surfaceDark : AppColors.surfaceLight),
            borderRadius: radius,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: radius,
            child: onTap != null
                ? InkWell(
                    borderRadius: radius,
                    splashColor: AppColors.primaryAccent.withValues(alpha: 0.12),
                    highlightColor: Colors.transparent,
                    onTap: onTap,
                    child: innerContent,
                  )
                : innerContent,
          ),
        ),
      );
    } else if (_variant == _CardVariant.dataGlass) {
      // Data card with subtle surface tint
      final surfaceTint = isDark
          ? AppColors.elevatedSurface(AppColors.surfaceDark, AppColors.elevationLevel2)
          : AppColors.surfaceLight;

      cardBody = Container(
        margin: margin,
        decoration: BoxDecoration(
          color: color ?? surfaceTint,
          borderRadius: radius,
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
            width: 1,
          ),
          boxShadow: isDark
              ? [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.02),
                    blurRadius: 1,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          child: onTap != null
              ? InkWell(
                  borderRadius: radius,
                  splashColor: AppColors.primaryAccent.withValues(alpha: 0.12),
                  onTap: onTap,
                  child: innerContent,
                )
              : innerContent,
        ),
      );
    } else {
      // Standard Card
      final cardColor = color ?? (isDark ? AppColors.surfaceDark : AppColors.surfaceLight);
      final border = borderColor ?? (isDark ? AppColors.dividerDark : AppColors.dividerLight);

      cardBody = Container(
        margin: margin,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: radius,
          border: Border.all(color: border, width: 1),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          child: onTap != null
              ? InkWell(
                  borderRadius: radius,
                  splashColor: AppColors.primaryAccent.withValues(alpha: 0.12),
                  onTap: onTap,
                  child: innerContent,
                )
              : innerContent,
        ),
      );
    }

    return RepaintBoundary(child: cardBody);
  }
}
