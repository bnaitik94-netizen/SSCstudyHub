import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../extensions/string_extensions.dart';

/// Lightweight avatar with memory caching and deterministic color initials fallback.
class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double size;
  final Widget? badge;

  const AppAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.size = 40.0,
    this.badge,
  });

  static const List<Color> _avatarColors = [
    Color(0xFF4F46E5), // Indigo
    Color(0xFF0EA5E9), // Sky
    Color(0xFF10B981), // Emerald
    Color(0xFFF59E0B), // Amber
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEC4899), // Pink
    Color(0xFF06B6D4), // Cyan
    Color(0xFFF97316), // Orange
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
          fontWeight: FontWeight.w600,
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

    if (badge != null) {
      return SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            avatarCore,
            Positioned(
              right: 0,
              bottom: 0,
              child: badge!,
            ),
          ],
        ),
      );
    }

    return avatarCore;
  }
}
