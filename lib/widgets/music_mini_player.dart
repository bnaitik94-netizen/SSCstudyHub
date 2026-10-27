import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/background_music_service.dart';

/// Professional floating/embedded music controller widget
class MusicMiniPlayer extends StatefulWidget {
  final bool compact;
  const MusicMiniPlayer({super.key, this.compact = false});

  @override
  State<MusicMiniPlayer> createState() => _MusicMiniPlayerState();
}

class _MusicMiniPlayerState extends State<MusicMiniPlayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  bool _isCollapsed = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _openTrackSelectorModal(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => const _MusicSelectorSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: BackgroundMusicService.instance,
      builder: (context, _) {
        final music = BackgroundMusicService.instance;
        final track = music.currentTrack;
        final isPlaying = music.isPlaying;

        if (widget.compact) {
          return _buildCompactPill(context, music, track, isPlaying);
        }

        return _buildFullFloatingPill(context, music, track, isPlaying);
      },
    );
  }

  Widget _buildCompactPill(
    BuildContext context,
    BackgroundMusicService music,
    BackgroundMusicTrack track,
    bool isPlaying,
  ) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0x2638BDF8),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: const Color(0x4D38BDF8)),
        boxShadow: [
          if (isPlaying)
            BoxShadow(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.2),
              blurRadius: 10,
              spreadRadius: 1,
            ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSoundWave(isPlaying),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 130),
            child: Text(
              track.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: Icon(
              isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.white,
              size: 18,
            ),
            splashRadius: 16,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            onPressed: () {
              HapticFeedback.lightImpact();
              music.userTogglePlayPause();
            },
          ),
          IconButton(
            icon: const Icon(Icons.skip_next_rounded, color: Colors.white70, size: 18),
            splashRadius: 16,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            tooltip: "Next Track",
            onPressed: () {
              HapticFeedback.lightImpact();
              music.nextTrack();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFullFloatingPill(
    BuildContext context,
    BackgroundMusicService music,
    BackgroundMusicTrack track,
    bool isPlaying,
  ) {
    if (_isCollapsed) {
      return Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _isCollapsed = false);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xE60F172A),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isPlaying ? const Color(0xFF38BDF8) : const Color(0x3364748B),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSoundWave(isPlaying),
                  const SizedBox(width: 6),
                  Icon(
                    isPlaying ? Icons.music_note_rounded : Icons.music_off_rounded,
                    color: isPlaying ? const Color(0xFF38BDF8) : Colors.white54,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xE60F172A),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isPlaying
                ? const Color(0x6638BDF8)
                : const Color(0x3364748B),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
            if (isPlaying)
              BoxShadow(
                color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
                blurRadius: 12,
                spreadRadius: 1,
              ),
          ],
        ),
        child: Row(
          children: [
            // Soundwave Icon / Button to open Track Selector
            GestureDetector(
              onTap: () => _openTrackSelectorModal(context),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isPlaying
                        ? [const Color(0xFF38BDF8), const Color(0xFF6366F1)]
                        : [const Color(0xFF334155), const Color(0xFF1E293B)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: _buildSoundWave(isPlaying),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Track details
            Expanded(
              child: GestureDetector(
                onTap: () => _openTrackSelectorModal(context),
                behavior: HitTestBehavior.opaque,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            track.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: isPlaying
                                ? const Color(0x3310B981)
                                : const Color(0x3364748B),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isPlaying ? "PLAYING" : "PAUSED",
                            style: TextStyle(
                              color: isPlaying ? const Color(0xFF34D399) : const Color(0xFF94A3B8),
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      track.subtitle,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),

            // Controls: Previous / Play-Pause / Next / Volume
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.skip_previous_rounded, color: Colors.white70, size: 20),
                  splashRadius: 18,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  tooltip: "Previous Track",
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    music.previousTrack();
                  },
                ),
                const SizedBox(width: 4),
                Material(
                  color: const Color(0xFF38BDF8),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      music.userTogglePlayPause();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(7),
                      child: Icon(
                        isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: const Color(0xFF0F172A),
                        size: 22,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.skip_next_rounded, color: Colors.white70, size: 20),
                  splashRadius: 18,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  tooltip: "Next Track",
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    music.nextTrack();
                  },
                ),
                const SizedBox(width: 2),
                IconButton(
                  icon: Icon(
                    music.isMuted
                        ? Icons.volume_off_rounded
                        : (music.volume < 0.4
                            ? Icons.volume_down_rounded
                            : Icons.volume_up_rounded),
                    color: const Color(0xFF38BDF8),
                    size: 20,
                  ),
                  splashRadius: 18,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  tooltip: "Sound & Track Menu",
                  onPressed: () => _openTrackSelectorModal(context),
                ),
                const SizedBox(width: 2),
                IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white54, size: 20),
                  splashRadius: 16,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                  tooltip: "Minimize Player",
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    setState(() => _isCollapsed = true);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoundWave(bool isPlaying) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, _) {
        final t = _animController.value * 2 * math.pi;
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(4, (i) {
            final double height = isPlaying
                ? 6.0 + 8.0 * ((math.sin(t + i * 1.3) + 1.0) / 2.0)
                : 4.0;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.2),
              width: 3.0,
              height: height,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}

/// Modal Sheet allowing students to switch songs, adjust background volume, and toggle mute
class _MusicSelectorSheet extends StatelessWidget {
  const _MusicSelectorSheet();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: BackgroundMusicService.instance,
      builder: (context, _) {
        final music = BackgroundMusicService.instance;
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          decoration: const BoxDecoration(
            color: Color(0xFF162544),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(color: Color(0x66FFFFFF), width: 1.2),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top handle
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0x3338BDF8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.music_note_rounded, color: Color(0xFF38BDF8), size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Background Study Music",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "Auto-pauses in class & when minimized",
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Track list
                ...List.generate(BackgroundMusicService.availableTracks.length, (index) {
                  final t = BackgroundMusicService.availableTracks[index];
                  final isSelected = music.currentTrackIndex == index;
                  final isCurrentlyPlaying = isSelected && music.isPlaying;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        music.play(index);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0x2638BDF8)
                              : Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF38BDF8)
                                : Colors.white.withValues(alpha: 0.08),
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF38BDF8).withValues(alpha: 0.2)
                                    : Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                t.icon,
                                color: isSelected ? const Color(0xFF38BDF8) : Colors.white70,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        t.title,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14.5,
                                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                        ),
                                      ),
                                      if (index == 0) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0x33F59E0B),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            "🔥 MOTIVATION",
                                            style: TextStyle(
                                              color: Color(0xFFFBBF24),
                                              fontSize: 9,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                      ] else if (index == 1) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0x3310B981),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            "🌿 FOCUS BEATS",
                                            style: TextStyle(
                                              color: Color(0xFF34D399),
                                              fontSize: 9,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    t.subtitle,
                                    style: const TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isCurrentlyPlaying)
                              const Icon(Icons.graphic_eq_rounded, color: Color(0xFF38BDF8), size: 22)
                            else if (isSelected)
                              const Icon(Icons.check_circle_rounded, color: Color(0xFF38BDF8), size: 20)
                            else
                              const Icon(Icons.play_circle_outline_rounded, color: Colors.white38, size: 22),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 16),
                const Divider(color: Colors.white12),
                const SizedBox(height: 12),

                // Volume slider section
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        music.isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                        color: music.isMuted ? const Color(0xFFEF4444) : const Color(0xFF38BDF8),
                      ),
                      tooltip: music.isMuted ? "Unmute" : "Mute",
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        music.toggleMute();
                      },
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: const Color(0xFF38BDF8),
                          inactiveTrackColor: Colors.white12,
                          thumbColor: Colors.white,
                          overlayColor: const Color(0x3338BDF8),
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                        ),
                        child: Slider(
                          value: music.isMuted ? 0.0 : music.volume,
                          min: 0.0,
                          max: 1.0,
                          onChanged: (val) => music.setVolume(val),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 42,
                      child: Text(
                        "${((music.isMuted ? 0.0 : music.volume) * 100).toInt()}%",
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
