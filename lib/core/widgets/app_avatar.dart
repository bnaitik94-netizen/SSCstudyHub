import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../extensions/string_extensions.dart';
import '../theme/app_colors.dart';

/// Studio-grade Avatar with memory caching, deterministic initials fallback,
/// and optional gradient ring border (Linear/Instagram inspired).
class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double size;
  final Widget? badge;
  final bool hasGradientRing;

  const AppAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.size = 40.0,
    this.badge,
    this.hasGradientRing = false,
  });

  static const List<Color> _avatarColors = [
    Color(0xFF6366F1), // Indigo
    Color(0xFF06B6D4), // Cyan
    Color(0xFF2ECC87), // Emerald
    Color(0xFFF59E0B), // Amber
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEC4899), // Pink
    Color(0xFFFF4D6A), // Rose
  ];

  Color _getColorForName(String str) {
    if (str.isEmpty) return _avatarColors[0];
    final hash = str.codeUnits.fold(0, (acc, c) => acc + c);
    return _avatarColors[hash % _avatarColors.length];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fallbackColor = _getColorForName(name);

    Widget fallbackWidget = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fallbackColor,
        shape: BoxShape.circle,
      ),
      child: Text(
        name.initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.4,
        ),
      ),
    );

    Widget avatarCore;

    if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      // PERF: memCacheWidth & memCacheHeight set to prevent bitmap decompression memory spikes
      final cachePx = (size * 2).toInt();
      avatarCore = ClipOval(
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          memCacheWidth: cachePx,
          memCacheHeight: cachePx,
          fadeInDuration: const Duration(milliseconds: 200),
          placeholder: (context, url) => Container(
            width: size,
            height: size,
            color: theme.colorScheme.surfaceContainer,
          ),
          errorWidget: (context, url, error) => fallbackWidget,
        ),
      );
    } else {
      avatarCore = fallbackWidget;
    }

    Widget renderedAvatar = avatarCore;

    if (hasGradientRing) {
      renderedAvatar = Container(
        padding: const EdgeInsets.all(2.5),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              AppColors.primaryAccent,
              AppColors.secondaryAccent,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(2.0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.scaffoldBackgroundColor,
          ),
          child: avatarCore,
        ),
      );
    }

    if (badge != null) {
      return SizedBox(
        width: hasGradientRing ? size + 9 : size,
        height: hasGradientRing ? size + 9 : size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            renderedAvatar,
            Positioned(
              right: 0,
              bottom: 0,
              child: badge!,
            ),
          ],
        ),
      );
    }

    return renderedAvatar;
  }
}
