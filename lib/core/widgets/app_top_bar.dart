import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Collapsing Sliver App Bar with Frosted Glassmorphism and Morphing Title.
/// Inspired by iOS large title bars and Linear navigation headers.
class AppSliverAppBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? leading;
  final double expandedHeight;
  final Widget? flexibleBottom;
  final bool pinned;

  const AppSliverAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.leading,
    this.expandedHeight = 120.0,
    this.flexibleBottom,
    this.pinned = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final frostedColor = isDark
        ? AppColors.backgroundDark.withValues(alpha: 0.8)
        : AppColors.backgroundLight.withValues(alpha: 0.85);

    return SliverAppBar(
      pinned: pinned,
      expandedHeight: expandedHeight,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: frostedColor,
      leading: leading,
      actions: actions,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double top = constraints.biggest.height;
              // 0.0 when fully collapsed, 1.0 when fully expanded
              final double collapseRatio = ((top - kToolbarHeight) / (expandedHeight - kToolbarHeight))
                  .clamp(0.0, 1.0);

              return FlexibleSpaceBar(
                centerTitle: false,
                titlePadding: EdgeInsetsDirectional.only(
                  start: leading != null ? 56 : AppSpacing.screenHorizontal,
                  bottom: 16,
                  end: AppSpacing.screenHorizontal,
                ),
                title: collapseRatio < 0.2
                    ? Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : null,
                background: Container(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenHorizontal,
                    kToolbarHeight + 8,
                    AppSpacing.screenHorizontal,
                    16,
                  ),
                  alignment: Alignment.bottomLeft,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            letterSpacing: 0.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (flexibleBottom != null) flexibleBottom!,
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Studio-grade custom Icon Button with circular ripple override & 44dp minimum touch target.
class AppIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? color;
  final Color? backgroundColor;
  final double size;

  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.color,
    this.backgroundColor,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconColor = color ?? theme.colorScheme.onSurface;

    Widget button = Material(
      color: backgroundColor ?? Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        splashColor: theme.colorScheme.primary.withValues(alpha: 0.15),
        highlightColor: theme.colorScheme.primary.withValues(alpha: 0.08),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: Icon(icon, size: size, color: iconColor),
        ),
      ),
    );

    if (tooltip != null) {
      button = Tooltip(message: tooltip!, child: button);
    }

    return button;
  }
}
