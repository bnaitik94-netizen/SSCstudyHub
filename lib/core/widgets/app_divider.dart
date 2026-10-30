import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

/// Ultra-thin 0.5dp divider with optional center label.
class AppDivider extends StatelessWidget {
  final String? label;
  final bool isVertical;
  final double indent;
  final double endIndent;
  final Color? color;

  const AppDivider({
    super.key,
    this.label,
    this.isVertical = false,
    this.indent = 0.0,
    this.endIndent = 0.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dividerColor = color ?? theme.colorScheme.outlineVariant;

    if (isVertical) {
      return VerticalDivider(
        width: 1,
        thickness: 0.5,
        indent: indent,
        endIndent: endIndent,
        color: dividerColor,
      );
    }

    if (label != null && label!.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Expanded(
              child: Divider(
                height: 1,
                thickness: 0.5,
                indent: indent,
                color: dividerColor,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                label!,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              child: Divider(
                height: 1,
                thickness: 0.5,
                endIndent: endIndent,
                color: dividerColor,
              ),
            ),
          ],
        ),
      );
    }

    return Divider(
      height: 1,
      thickness: 0.5,
      indent: indent,
      endIndent: endIndent,
      color: dividerColor,
    );
  }
}
