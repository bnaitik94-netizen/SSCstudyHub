import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackgroundMusicTrack {
  final String id;
  final String title;
  final String subtitle;
  final String assetName;
  final IconData icon;

  const BackgroundMusicTrack({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.assetName,
    required this.icon,
  });
}

class BackgroundMusicService extends ChangeNotifier {
  static final BackgroundMusicService instance = BackgroundMusicService._internal();

  BackgroundMusicService._internal();

  final AudioPlayer _player = AudioPlayer();

  static const List<BackgroundMusicTrack> availableTracks = [
    BackgroundMusicTrack(
      id: 'tu_hi_khiladi',
      title: 'Tu Hi Khiladi',
      subtitle: 'SSC Champion Anthem',
      assetName: 'audio/tu_hi_khiladi.mp3',
      icon: Icons.sports_score_rounded,
    ),
    BackgroundMusicTrack(
      id: 'deep_focus_study',
      title: 'Deep Focus Study',
      subtitle: 'Calm Ambient Lo-Fi',
      assetName: 'audio/deep_focus_study.mp3',
      icon: Icons.spa_rounded,
    ),
  ];

  int _currentIndex = 0;
  bool _isPlaying = false;
  bool _isMuted = false;
  double _volume = 0.65;
  bool _isInitialized = false;

  // Interruption flags
  bool _pausedForClass = false;
  bool _pausedForMinimize = false;
  bool _userExplicitlyPaused = false;

  int get currentTrackIndex => _currentIndex;
  BackgroundMusicTrack get currentTrack => availableTracks[_currentIndex];
  bool get isPlaying => _isPlaying;
  bool get isMuted => _isMuted;
  double get volume => _volume;
  bool get isInitialized => _isInitialized;
  bool get pausedForClass => _pausedForClass;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      _volume = prefs.getDouble('bg_music_volume') ?? 0.65;
      _currentIndex = prefs.getInt('bg_music_track_index') ?? 0;
      if (_currentIndex < 0 || _currentIndex >= availableTracks.length) {
        _currentIndex = 0;
      }
      _userExplicitlyPaused = prefs.getBool('bg_music_user_paused') ?? true;

      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(_isMuted ? 0.0 : _volume);

      _player.onPlayerStateChanged.listen((state) {
        final playing = state == PlayerState.playing;
        if (_isPlaying != playing) {
          _isPlaying = playing;
          notifyListeners();
        }
      });
    } catch (e) {
      debugPrint('[BackgroundMusicService] Init error: $e');
    }
  }

  Future<void> play([int? trackIndex]) async {
    try {
      if (trackIndex != null && trackIndex != _currentIndex) {
        _currentIndex = trackIndex % availableTracks.length;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('bg_music_track_index', _currentIndex);
      }

      _userExplicitlyPaused = false;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('bg_music_user_paused', false);

      final track = availableTracks[_currentIndex];
      await _player.setVolume(_isMuted ? 0.0 : _volume);
      await _player.play(AssetSource(track.assetName));
      _isPlaying = true;
      notifyListeners();
    } catch (e) {
      debugPrint('[BackgroundMusicService] Play error: $e');
    }
  }

  Future<void> pause() async {
    try {
      await _player.pause();
      _isPlaying = false;
      notifyListeners();
    } catch (e) {
      debugPrint('[BackgroundMusicService] Pause error: $e');
    }
  }

  Future<void> userTogglePlayPause() async {
    if (_isPlaying) {
      _userExplicitlyPaused = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('bg_music_user_paused', true);
      await pause();
    } else {
      _userExplicitlyPaused = false;
      await play();
    }
  }

  Future<void> nextTrack() async {
    final next = (_currentIndex + 1) % availableTracks.length;
    await play(next);
  }

  Future<void> previousTrack() async {
    final prev = (_currentIndex - 1 + availableTracks.length) % availableTracks.length;
    await play(prev);
  }

  Future<void> setVolume(double newVolume) async {
    _volume = newVolume.clamp(0.0, 1.0);
    if (_isMuted && _volume > 0.0) {
      _isMuted = false;
    }
    await _player.setVolume(_isMuted ? 0.0 : _volume);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('bg_music_volume', _volume);
    notifyListeners();
  }

  Future<void> toggleMute() async {
    _isMuted = !_isMuted;
    await _player.setVolume(_isMuted ? 0.0 : _volume);
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Classroom Intelligent Pausing & Resuming
  // ---------------------------------------------------------------------------
  Future<void> pauseForClass() async {
    debugPrint('[BackgroundMusicService] Pausing background music for class.');
    if (_isPlaying) {
      _pausedForClass = true;
      await pause();
    }
  }

  Future<void> resumeAfterClass() async {
    debugPrint('[BackgroundMusicService] Resuming background music after class.');
    if (_pausedForClass) {
      _pausedForClass = false;
      if (!_userExplicitlyPaused && !_pausedForMinimize) {
        await play();
      }
    }
  }

  // ---------------------------------------------------------------------------
  // App Lifecycle Minimize / Resumed
  // ---------------------------------------------------------------------------
  Future<void> onAppMinimized() async {
    if (_isPlaying) {
      debugPrint('[BackgroundMusicService] App minimized, pausing background music.');
      _pausedForMinimize = true;
      await pause();
    }
  }

  Future<void> onAppResumed() async {
    if (_pausedForMinimize) {
      debugPrint('[BackgroundMusicService] App resumed to foreground.');
      _pausedForMinimize = false;
      // Do not resume if user is currently inside a live or past class
      if (!_pausedForClass && !_userExplicitlyPaused) {
        await play();
      }
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
