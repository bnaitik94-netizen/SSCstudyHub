import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Master Loading Shimmer System:
/// - Exact gradient formula: surface -> surface + 15% white -> surface.
/// - Component-level inline shimmers (blocks, circles, text lines, cards).
/// - Page-level full skeleton layout (matches live dashboards and class lists).
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
    this.height = 110.0,
    this.radius = AppSpacing.radiusLg,
  });

  const AppLoadingShimmer.circle({
    super.key,
    required double size,
  })  : width = size,
        height = size,
        radius = AppSpacing.radiusPill;

  const AppLoadingShimmer.textLine({
    super.key,
    this.width = 120.0,
    this.height = 14.0,
    this.radius = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceMidLight;
    // Surface + 15% white overlay for highlight
    final highlight = Color.alphaBlend(Colors.white.withValues(alpha: 0.15), surface);

    return RepaintBoundary(
      child: Shimmer.fromColors(
        baseColor: surface,
        highlightColor: highlight,
        period: const Duration(milliseconds: 1400),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(radius ?? AppSpacing.radiusSm),
          ),
        ),
      ),
    );
  }

  /// Page-level full skeleton loading screen
  static Widget pageSkeleton({int itemCount = 4}) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero skeleton
          const AppLoadingShimmer(
            width: double.infinity,
            height: 140,
            radius: AppSpacing.radiusLg,
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          // Section header skeleton
          const AppLoadingShimmer.textLine(width: 140, height: 18),
          const SizedBox(height: AppSpacing.md),
          // List item skeletons
          Expanded(
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: itemCount,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (_, __) => const AppLoadingShimmer.card(height: 76),
            ),
          ),
        ],
      ),
    );
  }
}
