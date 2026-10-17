import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import '../utils/web_fullscreen_helper.dart';

/// Service for broadcasting and receiving real-time live class emoji reactions
class LiveReactionsService {
  static final StreamController<String> _localReactionStream =
      StreamController<String>.broadcast();
  static final Set<String> _locallySentPulseIds = {};

  static Stream<String> get localReactions => _localReactionStream.stream;

  static bool wasSentLocally(String pulseId) => _locallySentPulseIds.contains(pulseId);

  static Future<void> sendReaction(String emoji, String sender) async {
    try {
      if (!kIsWeb) HapticFeedback.lightImpact();
    } catch (_) {}
    // 1. Immediately emit locally for 0ms instantaneous feedback
    _localReactionStream.add(emoji);
    if (kIsWeb) {
      WebFullscreenHelper.dispatchSpawnEmoji(emoji);
    }

    // 2. Ultra-low latency broadcast (under 80ms) to Firestore for all students and teacher
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final pulseId = '${now}_${sender}_${Random().nextInt(99999)}';
      _locallySentPulseIds.add(pulseId);
      if (_locallySentPulseIds.length > 100) {
        _locallySentPulseIds.clear();
      }

      final sessionRef = FirebaseFirestore.instance.collection('live_session').doc('current');

      // Direct single-document write triggers snapshot listener in ~60-90ms across devices
      sessionRef.collection('realtime_feed').doc('reaction').set({
        'emoji': emoji,
        'sender': sender,
        'timestamp': now,
        'pulseId': pulseId,
      }, SetOptions(merge: true));

      // Also persist to reactions history for web admin compatibility
      sessionRef.collection('reactions').add({
        'emoji': emoji,
        'sender': sender,
        'timestamp': now,
      });
    } catch (e) {
      debugPrint("Reaction broadcast error: $e");
    }
  }
}

/// Floating reactions layer rendered directly over the live video stage
class FloatingReactionsLayer extends StatefulWidget {
  const FloatingReactionsLayer({super.key});

  @override
  State<FloatingReactionsLayer> createState() => _FloatingReactionsLayerState();
}

class _FloatingReactionsLayerState extends State<FloatingReactionsLayer> {
  final List<_ReactionParticle> _particles = [];
  final Random _random = Random();
  StreamSubscription<DocumentSnapshot>? _signalSub;
  StreamSubscription<String>? _localSub;
  String? _lastHandledPulseId;

  @override
  void initState() {
    super.initState();

    // 1. Local instant listener (0ms delay)
    _localSub = LiveReactionsService.localReactions.listen((emoji) {
      if (mounted) _spawnParticle(emoji);
    });

    // 2. Ultra-fast direct document stream (triggers in 60-90ms on remote devices)
    _signalSub = FirebaseFirestore.instance
        .collection('live_session')
        .doc('current')
        .collection('realtime_feed')
        .doc('reaction')
        .snapshots(includeMetadataChanges: false)
        .listen((docSnap) {
      if (!mounted || !docSnap.exists) return;
      final data = docSnap.data();
      if (data == null) return;

      final pulseId = data['pulseId']?.toString();
      if (pulseId != null && _lastHandledPulseId != pulseId) {
        _lastHandledPulseId = pulseId;
        // Don't re-spawn if this device already rendered it locally
        if (!LiveReactionsService.wasSentLocally(pulseId)) {
          final emoji = data['emoji']?.toString() ?? '❤️';
          _spawnParticle(emoji);
        }
      }
    });
  }

  void _spawnParticle(String emoji) {
    if (!mounted) return;
    final particle = _ReactionParticle(
      id: UniqueKey().toString(),
      emoji: emoji,
      startX: 16.0 + _random.nextDouble() * 45.0, // Floating along the right edge
      driftFactor: (_random.nextDouble() - 0.5) * 30.0,
      scaleFactor: 0.85 + _random.nextDouble() * 0.45,
    );

    setState(() {
      _particles.add(particle);
      if (_particles.length > 20) {
        _particles.removeAt(0);
      }
    });
  }

  void _removeParticle(String id) {
    if (!mounted) return;
    setState(() {
      _particles.removeWhere((p) => p.id == id);
    });
  }

  @override
  void dispose() {
    _signalSub?.cancel();
    _localSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: IgnorePointer(
        child: Stack(
          children: [
            for (final p in _particles)
              _FloatingParticleWidget(
                key: ValueKey(p.id),
                particle: p,
                onComplete: () => _removeParticle(p.id),
              ),
          ],
        ),
      ),
    );
  }
}

class _ReactionParticle {
  final String id;
  final String emoji;
  final double startX;
  final double driftFactor;
  final double scaleFactor;

  _ReactionParticle({
    required this.id,
    required this.emoji,
    required this.startX,
    required this.driftFactor,
    required this.scaleFactor,
  });
}

class _FloatingParticleWidget extends StatefulWidget {
  final _ReactionParticle particle;
  final VoidCallback onComplete;

  const _FloatingParticleWidget({
    super.key,
    required this.particle,
    required this.onComplete,
  });

  @override
  State<_FloatingParticleWidget> createState() =>
      _FloatingParticleWidgetState();
}

class _FloatingParticleWidgetState extends State<_FloatingParticleWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _progress = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _controller.forward().then((_) {
      if (mounted) widget.onComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progress,
      builder: (context, child) {
        final t = _progress.value;
        // Rising upwards across the video
        final bottomOffset = 20.0 + (t * 220.0);
        // Gentle sine wave side drift
        final rightOffset =
            widget.particle.startX + (sin(t * pi * 2.5) * widget.particle.driftFactor);
        // Fade out during last 35% of rise
        final opacity = (1.0 - t).clamp(0.0, 1.0);
        // Pop in scale
        final scale = (t < 0.2 ? (t / 0.2) : 1.0) * widget.particle.scaleFactor;

        return Positioned(
          bottom: bottomOffset,
          right: rightOffset,
          child: Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: scale,
              child: Text(
                widget.particle.emoji,
                style: const TextStyle(
                  fontSize: 28,
                  fontFamilyFallback: [
                    'Apple Color Emoji',
                    'Segoe UI Emoji',
                    'Noto Color Emoji',
                    'Android Emoji'
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Compact vertical emoji reaction column positioned on the right side of live chat
class EmojiReactionColumn extends StatelessWidget {
  final String userName;

  const EmojiReactionColumn({
    super.key,
    required this.userName,
  });

  static const List<String> _emojis = [
    '❤️',
    '🔥',
    '👏',
    '💡',
    '🚀',
    '🙋‍♂️',
  ];

  @override
  Widget build(BuildContext context) {
    return PointerInterceptor(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xEE0F172A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.18),
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x60000000),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final emoji in _emojis)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  mouseCursor: SystemMouseCursors.click,
                  onTap: () => LiveReactionsService.sendReaction(emoji, userName),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 3),
                    child: Text(
                      emoji,
                      style: const TextStyle(
                        fontSize: 19,
                        fontFamilyFallback: [
                          'Apple Color Emoji',
                          'Segoe UI Emoji',
                          'Noto Color Emoji',
                          'Android Emoji'
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
