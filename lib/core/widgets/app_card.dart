import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

/// Clean, high-performance card with zero elevation and subtle border.
/// Built for 60fps scrolling on low-end devices without GPU overdraw.
class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Color? borderColor;
  final double? borderRadius;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.color,
    this.borderColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedBorderRadius = BorderRadius.circular(borderRadius ?? AppSpacing.radiusMd);
    final resolvedBorderColor = borderColor ?? theme.colorScheme.outline;
    final resolvedColor = color ?? theme.colorScheme.surfaceContainerLow;

    // PERF: Avoid ClipRRect inside lists. Material handles ink ripple with shape borderRadius.
    Widget content = Padding(
      padding: padding ?? const EdgeInsets.all(AppSpacing.cardPadding),
      child: child,
    );

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: resolvedColor,
        borderRadius: resolvedBorderRadius,
        border: Border.all(color: resolvedBorderColor, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: resolvedBorderRadius,
        child: onTap != null
            ? InkWell(
                borderRadius: resolvedBorderRadius,
                onTap: onTap,
                child: content,
              )
            : content,
      ),
    );
  }
}
