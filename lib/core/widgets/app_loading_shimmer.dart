import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_spacing.dart';

/// Low-GPU overhead shimmer placeholder for low-end device lists and cards.
class AppLoadingShimmer extends StatelessWidget {
  final double width;
  final double height;
  final double? radius;

  const AppLoadingShimmer({
    super.key,
    required this.width,
    required this.height,
    this.radius,
  });

  const AppLoadingShimmer.card({
    super.key,
    this.width = double.infinity,
    this.height = 100.0,
    this.radius = AppSpacing.radiusMd,
  });

  const AppLoadingShimmer.circle({
    super.key,
    required double size,
  })  : width = size,
        height = size,
        radius = AppSpacing.radiusFull;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final baseColor = isDark
        ? theme.colorScheme.surfaceContainer
        : theme.colorScheme.surfaceContainerHigh;
    final highlightColor = isDark
        ? theme.colorScheme.surfaceContainerHigh
        : theme.colorScheme.surfaceContainerLowest;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      period: const Duration(milliseconds: 1500),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(radius ?? AppSpacing.radiusSm),
        ),
      ),
    );
  }
}
