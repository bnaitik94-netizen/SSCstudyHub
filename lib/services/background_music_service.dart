import 'dart:async';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:audioplayers/audioplayers.dart';

/// 🎵 ZERO-OVERHEAD INVISIBLE BACKGROUND MUSIC SERVICE
/// Automatically starts anthem on app launch, loops continuously,
/// auto-pauses when student enters live or past class,
/// auto-resumes when student exits class,
/// auto-pauses when app is minimized / backgrounded,
/// and has ZERO UI buttons, zero ticking animations, and zero main-thread overhead.
class BackgroundMusicService {
  static final BackgroundMusicService instance = BackgroundMusicService._internal();

  BackgroundMusicService._internal();

  AudioPlayer? _player;

  // Track & playback properties
  static const String anthemAsset = 'audio/tu_hi_khiladi.mp3';
  static const double backgroundVolume = 0.45; // Balanced, comfortable study volume

  bool _isPlaying = false;
  bool _pausedForClass = false;
  bool _pausedForMinimize = false;
  bool _interactionHandled = false;

  bool get isPlaying => _isPlaying;
  bool get pausedForClass => _pausedForClass;

  AudioPlayer get player {
    if (_player == null) {
      final p = AudioPlayer();
      _player = p;
      try {
        p.setReleaseMode(ReleaseMode.loop).catchError((_) {});
        p.setVolume(backgroundVolume).catchError((_) {});
        p.onPlayerStateChanged.listen((state) {
          _isPlaying = (state == PlayerState.playing);
        });
      } catch (e) {
        debugPrint('[BackgroundMusicService] AudioPlayer listener error: $e');
      }
    }
    return _player!;
  }

  /// Automatically start music when app loads
  Future<void> startAutoMusic() async {
    if (_isPlaying || _pausedForClass || _pausedForMinimize) return;
    try {
      await player.setVolume(backgroundVolume);
      await player.setReleaseMode(ReleaseMode.loop);
      await player.play(AssetSource(anthemAsset));
      _isPlaying = true;
      _interactionHandled = true;
    } catch (e) {
      // Browser autoplay policy might require first user gesture on web
      debugPrint('[BackgroundMusicService] Initial autoplay notice (waiting for first touch if on web): $e');
    }
  }

  /// Called on first user touch/click anywhere on screen to unlock audio if browser autoplay was blocked
  void onUserInteraction() {
    if (_interactionHandled && _isPlaying) return;
    if (_pausedForClass || _pausedForMinimize) return;

    _interactionHandled = true;
    if (!_isPlaying) {
      startAutoMusic();
    }
  }

  /// ⏸️ Auto-pause when student enters live or past class
  Future<void> pauseForClass() async {
    debugPrint('[BackgroundMusicService] Entering class -> Auto-pausing background music.');
    _pausedForClass = true;
    if (_isPlaying && _player != null) {
      try {
        await _player!.pause();
        _isPlaying = false;
      } catch (e) {
        debugPrint('[BackgroundMusicService] Pause error: $e');
      }
    }
  }

  /// ▶️ Auto-resume when student exits class back to dashboard
  Future<void> resumeAfterClass() async {
    debugPrint('[BackgroundMusicService] Exiting class -> Auto-resuming background music.');
    _pausedForClass = false;
    if (!_pausedForMinimize) {
      await startAutoMusic();
    }
  }

  /// ⏸️ Auto-pause when app is minimized / backgrounded / tab hidden
  Future<void> onAppMinimized() async {
    debugPrint('[BackgroundMusicService] App minimized -> Pausing background music.');
    _pausedForMinimize = true;
    if (_isPlaying && _player != null) {
      try {
        await _player!.pause();
        _isPlaying = false;
      } catch (e) {
        debugPrint('[BackgroundMusicService] App minimized pause error: $e');
      }
    }
  }

  /// ▶️ Auto-resume when coming back to foreground
  Future<void> onAppResumed() async {
    debugPrint('[BackgroundMusicService] App resumed -> Resuming background music.');
    _pausedForMinimize = false;
    // Only resume if student is not currently inside a class
    if (!_pausedForClass) {
      await startAutoMusic();
    }
  }

  void dispose() {
    try {
      _player?.dispose();
    } catch (_) {}
  }
}
