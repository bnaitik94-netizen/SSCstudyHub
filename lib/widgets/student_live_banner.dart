import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/live_class_preload_engine.dart';
import '../screens/jitsi_live_class_screen.dart';
import '../screens/youtube_live_player_screen.dart';

class StudentLiveBanner extends StatelessWidget {
  final LiveClassPreloadEngine engine;

  const StudentLiveBanner({super.key, required this.engine});

  void _openJitsiScreen(BuildContext context) {
    HapticFeedback.mediumImpact();
    if (!engine.permissionsGranted) {
      engine.promptPermissionSettings(context);
      return;
    }

    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, __, ___) => const JitsiLiveClassScreen(),
      ),
    );
  }

  void _openYoutubeScreen(BuildContext context) {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, __, ___) => const YouTubeLivePlayerScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!engine.isClassLive) {
      return const SizedBox.shrink();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Pulsing Live Badge & Pre-load Ready Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const RepaintBoundary(
                    child: _PulsingLiveBadge(),
                  ),
                  RepaintBoundary(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2ECC87).withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF2ECC87).withValues(alpha: 0.4)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bolt_rounded, size: 12, color: Color(0xFF2ECC87)),
                          SizedBox(width: 4),
                          Text(
                            "0ms Instant Launch",
                            style: TextStyle(
                              color: Color(0xFF2ECC87),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),
              Text(
                engine.subject,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                engine.topic,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 18),

              // Action Buttons
              Row(
                children: [
                  if (engine.isJitsiPreloaded)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _openJitsiScreen(context),
                        icon: const Icon(Icons.video_camera_front_rounded, size: 18, color: Colors.black),
                        label: const Text(
                          "Join Jitsi Live",
                          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00F2FE),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                      ),
                    ),

                  if (engine.isJitsiPreloaded && engine.isYoutubePrewarmed)
                    const SizedBox(width: 10),

                  if (engine.isYoutubePrewarmed)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _openYoutubeScreen(context),
                        icon: const Icon(Icons.play_circle_fill_rounded, size: 18, color: Colors.white),
                        label: const Text(
                          "Watch HD Stream",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF0055),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PulsingLiveBadge extends StatefulWidget {
  const _PulsingLiveBadge();

  @override
  State<_PulsingLiveBadge> createState() => _PulsingLiveBadgeState();
}

class _PulsingLiveBadgeState extends State<_PulsingLiveBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFF0055).withValues(alpha: 0.20 + (_ctrl.value * 0.15)),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFFF0055).withValues(alpha: 0.6)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFF0055),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF0055).withValues(alpha: 0.8),
                      blurRadius: 4 + (_ctrl.value * 4),
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                "LIVE NOW",
                style: TextStyle(
                  color: Color(0xFFFF0055),
                  fontWeight: FontWeight.w900,
                  fontSize: 10.5,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
