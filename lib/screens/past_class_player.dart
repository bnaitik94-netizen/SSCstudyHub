// past_class_player.dart
//
// Recorded-class player: YouTube playback with smart resume, remembered
// playback speed, gesture / keyboard seeking, adaptive layouts and the
// embedded AI-doubts panel.
//
// Behaviour
//   • Resume: progress is saved every few seconds and on pause / background /
//     exit, then restored once the player is ready ("Resumed from 12:34 ·
//     Start over"). Finished videos (last 15 s or ended) restart from 0:00.
//   • Speed: chosen playback speed is remembered between classes.
//   • Touch: tap = show / hide controls · double-tap left / right = ∓10 s.
//   • Keyboard (web / desktop / hardware keyboards): Space or K play / pause ·
//     ← → seek 5 s · J L seek 10 s · F rotate. Ignored while typing a doubt.
//   • Layouts: portrait · phone landscape (full screen, doubts slide in) ·
//     tablet / web landscape (video and doubts side by side).
//
// Requires Flutter 3.22+ (uses PopScope.onPopInvokedWithResult). The chat is
// kept alive across layout changes with a GlobalKey, so DoubtsPanel must accept
// a `key` (i.e. `const DoubtsPanel({super.key})`).

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../utils/app_colors.dart';
import '../widgets/doubts_panel.dart';
import '../widgets/web_player_loader.dart';
import '../utils/web_fullscreen_helper.dart';
import '../utils/web_navigation_helper.dart';

/// Platform-aware pointer interceptor:
/// Only activates on Web to stop iframe click stealing.
/// On native Android/iOS, passes through directly with 0 platform view overhead!
class _PlatformPointerInterceptor extends StatelessWidget {
  final Widget child;
  const _PlatformPointerInterceptor({required this.child});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return PointerInterceptor(child: child);
    return child;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tunables
// ─────────────────────────────────────────────────────────────────────────────

const Duration _kSeekStep = Duration(seconds: 10);
const Duration _kKeyboardSeekStep = Duration(seconds: 5);
const Duration _kOverlayHideDelay = Duration(milliseconds: 3500);
const Duration _kSaveThrottle = Duration(seconds: 3);

/// Positions earlier than this are not worth resuming from.
const Duration _kMinResume = Duration(seconds: 5);

/// Positions this close to the end count as "finished" (no resume offered).
const Duration _kFinishedTail = Duration(seconds: 15);

const Duration _kSlowLoadAfter = Duration(seconds: 15);
const Duration _kResumeBannerFor = Duration(seconds: 6);

/// Landscape windows at least this wide get the side-by-side layout.
const double _kSplitBreakpoint = 900;

/// ...and the window must be tablet-class, so large phones keep the immersive
/// full-screen layout.
const double _kTabletShortestSide = 600;
const double _kPhonePanelWidth = 340;
const double _kSplitPanelWidth = 380;

const String _kRatePrefKey = 'past_class_playback_rate';
const List<double> _kPlaybackRates = <double>[
  0.5,
  0.75,
  1.0,
  1.25,
  1.5,
  1.75,
  2.0,
];

const Color _kPillBackground = Color(0x99000000);

/// Played-progress colour (YouTube red, as in the original design).
const Color _kProgressColor = Colors.red;

/// Soft top/bottom scrim so white controls stay readable on bright slides.
const BoxDecoration _kScrim = BoxDecoration(
  gradient: LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[
      Color(0xB3000000),
      Color(0x00000000),
      Color(0x00000000),
      Color(0xCC000000),
    ],
    stops: <double>[0.0, 0.32, 0.55, 1.0],
  ),
);

// ─────────────────────────────────────────────────────────────────────────────
// Public widget
// ─────────────────────────────────────────────────────────────────────────────

class PastClassPlayerScreen extends StatefulWidget {
  const PastClassPlayerScreen({
    super.key,
    required this.videoId,
    required this.title,
    this.restoreOrientations,
  });

  /// A YouTube video id or any common YouTube URL.
  final String videoId;

  /// Class title shown in the player and under the video.
  final String title;

  /// Orientations re-enabled when this screen closes. Defaults to all of them;
  /// pass e.g. `[DeviceOrientation.portraitUp]` if the rest of the app is
  /// portrait-only.
  final List<DeviceOrientation>? restoreOrientations;

  @override
  State<PastClassPlayerScreen> createState() => _PastClassPlayerScreenState();
}

// ─────────────────────────────────────────────────────────────────────────────
// Small value types
// ─────────────────────────────────────────────────────────────────────────────

enum _PlayerLayout {
  /// Phone portrait: video on top, doubts below.
  portrait,

  /// Phone landscape: full-screen video, doubts slide in from the right.
  immersive,

  /// Tablet / web landscape: video and doubts side by side.
  split,
}

/// The slice of player state the UI cares about. Equality lets the screen
/// rebuild only when something visible actually changed.
@immutable
class _PlaybackUi {
  const _PlaybackUi({
    this.isReady = false,
    this.isPlaying = false,
    this.isPaused = false,
    this.isBuffering = false,
    this.hasEnded = false,
    this.rate = 1.0,
    this.errorCode = 0,
  });

  final bool isReady;
  final bool isPlaying;
  final bool isPaused;
  final bool isBuffering;
  final bool hasEnded;
  final double rate;
  final int errorCode;

  bool get hasError => errorCode != 0;

  @override
  bool operator ==(Object other) =>
      other is _PlaybackUi &&
      other.isReady == isReady &&
      other.isPlaying == isPlaying &&
      other.isPaused == isPaused &&
      other.isBuffering == isBuffering &&
      other.hasEnded == hasEnded &&
      other.rate == rate &&
      other.errorCode == errorCode;

  @override
  int get hashCode => Object.hash(
        isReady,
        isPlaying,
        isPaused,
        isBuffering,
        hasEnded,
        rate,
        errorCode,
      );
}

/// Feedback badge for double-tap / keyboard seeking ("« 20 sec").
class _SeekPulse {
  const _SeekPulse({required this.forward, required this.seconds});

  final bool forward;
  final int seconds;
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen state
// ─────────────────────────────────────────────────────────────────────────────

class _PastClassPlayerScreenState extends State<PastClassPlayerScreen>
    with WidgetsBindingObserver {
  late final YoutubePlayerController _controller;

  late final String _videoId =
      YoutubePlayer.convertUrlToId(widget.videoId) ?? widget.videoId;

  /// Unchanged from earlier versions, so progress saved before this update is
  /// still found.
  String get _positionKey => 'past_class_position_$_videoId';

  // ── Keys & focus ──────────────────────────────────────────────────────────

  /// Keeps the YoutubePlayer element (and its WebView) alive while the layout
  /// moves between portrait / immersive / split. There is exactly one player.
  /// Only replaced by _retry() when the page never finished loading.
  GlobalKey _playerKey = GlobalKey(debugLabel: 'past_class_player');

  /// Same idea for the chat: typed text, scroll position and in-flight AI
  /// replies survive rotation and opening / closing the side panel.
  final GlobalKey _doubtsKey = GlobalKey(debugLabel: 'past_class_doubts');

  final FocusNode _keyFocus = FocusNode(debugLabel: 'past_class_shortcuts');

  // ── Fine-grained UI state ─────────────────────────────────────────────────
  // Each notifier rebuilds only the small subtree that listens to it, so the
  // frequent position updates never rebuild the whole screen.

  final ValueNotifier<_PlaybackUi> _ui =
      ValueNotifier<_PlaybackUi>(const _PlaybackUi());
  final ValueNotifier<bool> _overlaysVisible = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _slowLoad = ValueNotifier<bool>(false);
  final ValueNotifier<_SeekPulse?> _seekPulse =
      ValueNotifier<_SeekPulse?>(null);
  final ValueNotifier<Duration?> _resumeBanner =
      ValueNotifier<Duration?>(null);

  // ── Timers ────────────────────────────────────────────────────────────────

  Timer? _overlayTimer;
  Timer? _saveTimer;
  Timer? _slowLoadTimer;
  Timer? _seekPulseTimer;
  Timer? _bannerTimer;

  // ── Saved progress & preferences ──────────────────────────────────────────

  SharedPreferences? _prefs;
  bool _prefsLoaded = false;

  /// One-time "player is ready" work (resume, speed, autoplay) has run.
  bool _started = false;

  /// Until the resume decision is made nothing may be saved, otherwise the
  /// first seconds of playback could overwrite the progress we want to restore.
  bool _resumeSettled = false;

  Duration? _resumeTarget;
  Duration _appliedResume = Duration.zero;
  bool _tailCheckPending = false;

  double _preferredRate = 1.0;
  bool _rateConfirmed = false;

  Duration _lastPosition = Duration.zero;
  Duration _lastSaved = Duration.zero;

  // ── Layout state ──────────────────────────────────────────────────────────

  /// `null` means "use the layout's default" (open in split, closed in
  /// immersive).
  bool? _panelPref;

  _PlayerLayout? _chromeLayout;
  bool _chromeRestored = false;
  StreamSubscription? _fullscreenSub;
  StreamSubscription? _playerBackSub;
  StreamSubscription? _playerSyncSub;
  StreamSubscription? _playerFSSub;
  StreamSubscription? _playerChatSub;
  StreamSubscription? _playerDoubtsSub;

  bool get _canRotate =>
      kIsWeb ||
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  // ───────────────────────────── Lifecycle ──────────────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    try {
      WakelockPlus.enable();
    } catch (_) {}

    if (kIsWeb) {
      WebNavigationHelper.updateUrl('/watch?v=$_videoId');
      _fullscreenSub = WebFullscreenHelper.listenFullscreenChange((isFs) {
        if (mounted) setState(() {});
      });
      _playerBackSub = WebFullscreenHelper.listenPlayerBack(() {
        if (mounted) _goBack();
      });
      _playerSyncSub = WebFullscreenHelper.listenPlayerSync(() {
        if (mounted) _replay();
      });
      _playerFSSub = WebFullscreenHelper.listenPlayerFullscreen(() {
        if (mounted) _pokeOverlays();
      });
      _playerChatSub = WebFullscreenHelper.listenPlayerChat(() {
        if (mounted) _setPanelOpen(true);
      });
      _playerDoubtsSub = WebFullscreenHelper.listenPlayerDoubts(() {
        if (mounted) _setPanelOpen(true);
      });
    }

    // The player is already a heavy GPU / WebView surface, so pause the app's
    // animated background while this screen is open.
    AppColors.isBackgroundAnimating.value = false;

    _controller = YoutubePlayerController(
      initialVideoId: _videoId,
      flags: const YoutubePlayerFlags(
        // Playback is started by _maybeStart() once the saved position has
        // been applied, so the video never flashes 0:00 before jumping.
        autoPlay: false,
        isLive: false,
        forceHD: false,
        mute: false,
        hideControls: true,
        enableCaption: false,
        useHybridComposition: false, // ⚡ FAST LOAD: Instant texture-backed loading without Hybrid Composition lag
      ),
    )..addListener(_onPlayerValue);

    if (_canRotate) {
      SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }

    _armSlowLoadTimer();
    _scheduleOverlayHide();
    unawaited(_loadPreferences());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Runs only when the window size / orientation changes (not on every
    // keyboard frame), so system bars are touched exactly when needed.
    _applySystemChrome(_layoutOf(context));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _persistPosition();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    try {
      WakelockPlus.disable();
    } catch (_) {}

    if (kIsWeb) {
      WebNavigationHelper.updateUrl('/classes');
    }

    for (final timer in <Timer?>[
      _overlayTimer,
      _saveTimer,
      _slowLoadTimer,
      _seekPulseTimer,
      _bannerTimer,
    ]) {
      timer?.cancel();
    }

    // Read the position while the player still exists; the disk write itself
    // is fire-and-forget.
    _persistPosition();

    _controller
      ..removeListener(_onPlayerValue)
      ..dispose();

    if (!kIsWeb) {
      WakelockPlus.disable();
      _restoreSystemChrome();
    } else {
      _fullscreenSub?.cancel();
      _playerBackSub?.cancel();
      _playerSyncSub?.cancel();
      _playerFSSub?.cancel();
      _playerChatSub?.cancel();
      _playerDoubtsSub?.cancel();
      if (WebFullscreenHelper.isFullscreen()) {
        WebFullscreenHelper.exitFullscreen();
      }
    }
    AppColors.isBackgroundAnimating.value = true;

    _ui.dispose();
    _overlaysVisible.dispose();
    _slowLoad.dispose();
    _seekPulse.dispose();
    _resumeBanner.dispose();
    _keyFocus.dispose();

    super.dispose();
  }

  // ─────────────────────────── System chrome ────────────────────────────────

  _PlayerLayout _layoutOf(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    if (size.width <= size.height) return _PlayerLayout.portrait;

    final isTabletClass = size.shortestSide >= _kTabletShortestSide;
    return isTabletClass && size.width >= _kSplitBreakpoint
        ? _PlayerLayout.split
        : _PlayerLayout.immersive;
  }

  void _applySystemChrome(_PlayerLayout layout) {
    if (kIsWeb) return;
    if (_chromeRestored || _chromeLayout == layout) return;
    _chromeLayout = layout;

    unawaited(
      SystemChrome.setEnabledSystemUIMode(
        layout == _PlayerLayout.immersive
            ? SystemUiMode.immersiveSticky
            : SystemUiMode.edgeToEdge,
      ),
    );
  }

  /// Safe to call more than once. Runs as soon as the pop starts (so the
  /// previous screen is already upright during the transition) and again from
  /// dispose() as a safety net.
  void _restoreSystemChrome() {
    if (kIsWeb) return;
    _chromeRestored = true;
    unawaited(
      SystemChrome.setPreferredOrientations(
        widget.restoreOrientations ?? DeviceOrientation.values,
      ),
    );
    unawaited(SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
  }

  // ───────────────────── Preferences, resume & start-up ─────────────────────

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      _prefs = prefs;

      final savedSeconds = prefs.getInt(_positionKey) ?? 0;
      if (savedSeconds >= _kMinResume.inSeconds) {
        _resumeTarget = Duration(seconds: savedSeconds);
      }

      final savedRate = prefs.getDouble(_kRatePrefKey);
      if (savedRate != null && _kPlaybackRates.contains(savedRate)) {
        _preferredRate = savedRate;
      }
    } catch (e) {
      debugPrint('PastClassPlayer: could not read preferences: $e');
    } finally {
      _prefsLoaded = true;
    }

    _maybeStart();
  }

  /// Runs exactly once, as soon as BOTH the saved preferences and the player
  /// are ready (whichever finishes last triggers it).
  void _maybeStart() {
    if (!mounted ||
        _started ||
        !_prefsLoaded ||
        !_controller.value.isReady) {
      return;
    }
    _started = true;

    _slowLoadTimer?.cancel();
    _slowLoad.value = false;

    if (_preferredRate != 1.0) _controller.setPlaybackRate(_preferredRate);

    final target = _resumeTarget;
    _resumeTarget = null;
    if (target != null) {
      _appliedResume = target;
      _tailCheckPending = true;
      _lastPosition = target;
      _controller.seekTo(target);
      _showResumeBanner(target);
    }

    _resumeSettled = true;

    // Browsers block autoplay without a user gesture; on web the first tap on
    // the play button starts the video.
    if (!kIsWeb) {
      _controller.play();
      WakelockPlus.enable();
    }
  }

  void _armSlowLoadTimer() {
    _slowLoadTimer?.cancel();
    _slowLoad.value = false;
    _slowLoadTimer = Timer(_kSlowLoadAfter, () {
      if (mounted && !_controller.value.isReady) _slowLoad.value = true;
    });
  }

  void _showResumeBanner(Duration at) {
    _resumeBanner.value = at;
    _bannerTimer?.cancel();
    _bannerTimer = Timer(_kResumeBannerFor, () => _resumeBanner.value = null);
  }

  void _startOver() {
    _bannerTimer?.cancel();
    _resumeBanner.value = null;
    _tailCheckPending = false;
    _controller.seekTo(Duration.zero);
    _clearSavedPosition();
    _pokeOverlays();
  }

  /// Progress written by older versions could point at the very end of the
  /// video. Once the duration is known, restart from the beginning instead.
  void _verifyResumeIsNotAtEnd() {
    final duration = _controller.metadata.duration;
    if (duration <= Duration.zero) return; // Metadata not here yet; retry.

    _tailCheckPending = false;
    if (_appliedResume >= duration - _kFinishedTail) {
      _controller.seekTo(Duration.zero);
      _resumeBanner.value = null;
      _clearSavedPosition();
    }
  }

  // ─────────────────────────── Player listener ──────────────────────────────

  void _onPlayerValue() {
    final value = _controller.value;
    final state = value.playerState;
    final isActive =
        state == PlayerState.playing || state == PlayerState.buffering;

    final next = _PlaybackUi(
      isReady: value.isReady,
      isPlaying: state == PlayerState.playing,
      isPaused: state == PlayerState.paused,
      isBuffering: state == PlayerState.buffering,
      hasEnded: state == PlayerState.ended,
      rate: value.playbackRate,
      // A stale error code must not linger once playback has recovered.
      errorCode: isActive ? 0 : value.errorCode,
    );

    final previous = _ui.value;
    if (next != previous) {
      _ui.value = next;
      _handleTransition(previous, next);
    }

    final position = value.position;
    if (position > Duration.zero) {
      _lastPosition = position;
      if (next.isPlaying) _scheduleSave();
    }

    if (_tailCheckPending && next.isPlaying) _verifyResumeIsNotAtEnd();
  }

  void _handleTransition(_PlaybackUi prev, _PlaybackUi next) {
    if (!prev.isReady && next.isReady) _maybeStart();

    // ⚡ ORIENTATION POSITION RECOVERY: If player resets to 0:00 on rotation, restore position instantly
    if (next.isReady &&
        _lastPosition >= _kMinResume &&
        _controller.value.position < const Duration(seconds: 1)) {
      _controller.seekTo(_lastPosition);
      if (next.isPlaying || prev.isPlaying) _controller.play();
    }

    if (next.isPlaying && !prev.isPlaying) {
      _scheduleOverlayHide();
      _confirmPlaybackRate();
    }

    final justPaused = next.isPaused && !prev.isPaused;
    final justEnded = next.hasEnded && !prev.hasEnded;
    final justFailed = next.hasError && !prev.hasError;

    if (justPaused) _persistPosition();
    if (justEnded) _clearSavedPosition();

    // Keep the controls on screen whenever the viewer is most likely to need
    // them.
    if (justPaused || justEnded || justFailed) {
      _overlayTimer?.cancel();
      _overlaysVisible.value = true;
    }
  }

  /// YouTube can ignore a rate set before playback begins, so verify once the
  /// video is really playing.
  void _confirmPlaybackRate() {
    if (_rateConfirmed) return;
    _rateConfirmed = true;

    if ((_controller.value.playbackRate - _preferredRate).abs() > 0.001) {
      _controller.setPlaybackRate(_preferredRate);
    }
  }

  // ───────────────────────── Saving progress ────────────────────────────────

  void _scheduleSave() {
    if (!_resumeSettled || (_saveTimer?.isActive ?? false)) return;
    _saveTimer = Timer(_kSaveThrottle, _persistPosition);
  }

  /// Synchronously reads the player, then writes to disk without blocking.
  void _persistPosition() {
    if (_prefs == null || !_resumeSettled) return;

    final value = _controller.value;
    final position = value.position;
    final duration = _controller.metadata.duration;

    // Finished (or nearly): the next visit starts from the beginning.
    final finished = value.playerState == PlayerState.ended ||
        (duration > Duration.zero && position >= duration - _kFinishedTail);
    if (finished) {
      _clearSavedPosition();
      return;
    }

    if (position < _kMinResume) return;
    if ((position - _lastSaved).abs() < const Duration(seconds: 1)) return;

    _lastSaved = position;
    final seconds = position.inSeconds;
    unawaited(_prefsWrite((prefs) => prefs.setInt(_positionKey, seconds)));
  }

  void _clearSavedPosition() {
    _lastSaved = Duration.zero;
    unawaited(_prefsWrite((prefs) => prefs.remove(_positionKey)));
  }

  Future<void> _prefsWrite(
    Future<bool> Function(SharedPreferences prefs) write,
  ) async {
    final prefs = _prefs;
    if (prefs == null) return;
    try {
      await write(prefs);
    } catch (e) {
      debugPrint('PastClassPlayer: could not write preferences: $e');
    }
  }

  // ───────────────────────────── Overlays ───────────────────────────────────

  void _toggleOverlays() {
    final show = !_overlaysVisible.value;
    _overlaysVisible.value = show;
    if (show) {
      _scheduleOverlayHide();
    } else {
      _overlayTimer?.cancel();
    }
  }

  void _pokeOverlays() {
    _overlaysVisible.value = true;
    _scheduleOverlayHide();
  }

  void _scheduleOverlayHide() {
    _overlayTimer?.cancel();
    _overlayTimer = Timer(_kOverlayHideDelay, () {
      // Controls stay up while paused, ended or failed, so they never vanish
      // exactly when the viewer needs them.
      if (mounted && _ui.value.isPlaying) _overlaysVisible.value = false;
    });
  }

  void _onSurfaceTap() {
    // Reclaim keyboard focus (this also dismisses the chat keyboard) so the
    // shortcuts keep working after the viewer has been typing.
    _keyFocus.requestFocus();
    _toggleOverlays();
  }

  // ───────────────────────────── Playback ───────────────────────────────────

  void _togglePlayPause() {
    final ui = _ui.value;
    if (!ui.isReady) return;

    if (ui.hasEnded) {
      _replay();
      return;
    }

    if (ui.isPlaying || ui.isBuffering) {
      _controller.pause();
      if (!kIsWeb) WakelockPlus.disable();
    } else {
      _controller.play();
      if (!kIsWeb) WakelockPlus.enable();
    }
    _pokeOverlays();
  }

  void _replay() {
    _controller
      ..seekTo(Duration.zero)
      ..play();
    if (!kIsWeb) WakelockPlus.enable();
    _pokeOverlays();
  }

  void _seekBy(Duration delta) {
    if (!_ui.value.isReady) return;

    final duration = _controller.metadata.duration;
    var target = _controller.value.position + delta;

    if (target < Duration.zero) target = Duration.zero;
    if (duration > Duration.zero) {
      final latest = duration - const Duration(seconds: 1);
      if (target > latest) {
        target = latest > Duration.zero ? latest : Duration.zero;
      }
    }

    // The package's seekTo() also calls play(); put a paused video back.
    final wasPaused = _ui.value.isPaused;
    _controller.seekTo(target);
    if (wasPaused) _controller.pause();

    _showSeekPulse(forward: !delta.isNegative, seconds: delta.inSeconds.abs());

    // A double-tap on a hidden surface must not pop the controls up.
    if (_overlaysVisible.value) _scheduleOverlayHide();
  }

  void _showSeekPulse({required bool forward, required int seconds}) {
    final current = _seekPulse.value;
    final base =
        current != null && current.forward == forward ? current.seconds : 0;

    // Repeated taps in the same direction accumulate: 10 → 20 → 30 sec.
    _seekPulse.value = _SeekPulse(forward: forward, seconds: base + seconds);

    _seekPulseTimer?.cancel();
    _seekPulseTimer = Timer(
      const Duration(milliseconds: 750),
      () => _seekPulse.value = null,
    );
  }

  void _setRate(double rate) {
    _preferredRate = rate;
    _controller.setPlaybackRate(rate);
    unawaited(_prefsWrite((prefs) => prefs.setDouble(_kRatePrefKey, rate)));
  }

  Future<void> _showSpeedSheet() async {
    _overlayTimer?.cancel();

    final picked = await showModalBottomSheet<double>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _SpeedSheet(current: _ui.value.rate),
    );

    if (!mounted) return;
    if (picked != null) _setRate(picked);
    _pokeOverlays();
  }

  void _retry() {
    _armSlowLoadTimer();

    if (_controller.value.isReady) {
      final resumeAt =
          _lastPosition >= _kMinResume ? _lastPosition.inSeconds : 0;
      _controller.load(_videoId, startAt: resumeAt);
    } else {
      // The page never finished loading (e.g. the screen was opened offline):
      // build a fresh WebView around the same controller.
      setState(() => _playerKey = GlobalKey(debugLabel: 'past_class_player'));
    }
  }

  void _goBack() => unawaited(Navigator.of(context).maybePop());

  // ─────────────────────── Rotation & side panel ────────────────────────────

  Future<void> _toggleFullScreen() async {
    if (!_canRotate) return;

    // Cheap insurance: save before the surface is resized by the rotation.
    _persistPosition();

    if (kIsWeb) {
      await WebFullscreenHelper.toggleFullscreen();
      if (mounted) _pokeOverlays();
      return;
    }

    final isLandscape = _layoutOf(context) != _PlayerLayout.portrait;
    await SystemChrome.setPreferredOrientations(
      isLandscape
          ? const <DeviceOrientation>[
              DeviceOrientation.portraitUp,
              DeviceOrientation.portraitDown,
            ]
          : const <DeviceOrientation>[
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ],
    );

    if (mounted) _pokeOverlays();
  }

  bool _isPanelOpen(_PlayerLayout layout) => switch (layout) {
        _PlayerLayout.portrait => true,
        _PlayerLayout.split => _panelPref ?? true,
        _PlayerLayout.immersive => _panelPref ?? false,
      };

  void _setPanelOpen(bool open) {
    setState(() => _panelPref = open);

    if (open) {
      // Same as before: get the controls out of the chat's way.
      _overlayTimer?.cancel();
      _overlaysVisible.value = false;
    } else {
      FocusManager.instance.primaryFocus?.unfocus();
      _keyFocus.requestFocus();
      _pokeOverlays();
    }
  }

  // ───────────────────────────── Keyboard ───────────────────────────────────

  /// True while the viewer is typing a doubt, so Space / arrows are left alone.
  bool get _isTypingInTextField {
    final focusContext = FocusManager.instance.primaryFocus?.context;
    if (focusContext == null) return false;
    return focusContext.widget is EditableText ||
        focusContext.findAncestorWidgetOfExactType<EditableText>() != null;
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent || _isTypingInTextField) {
      return KeyEventResult.ignored;
    }

    final keyboard = HardwareKeyboard.instance;
    if (keyboard.isControlPressed ||
        keyboard.isMetaPressed ||
        keyboard.isAltPressed) {
      return KeyEventResult.ignored;
    }

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.space || key == LogicalKeyboardKey.keyK) {
      if (event is! KeyRepeatEvent) _togglePlayPause();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft) {
      _seekBy(-_kKeyboardSeekStep);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      _seekBy(_kKeyboardSeekStep);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyJ) {
      _seekBy(-_kSeekStep);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyL) {
      _seekBy(_kSeekStep);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyF && _canRotate) {
      if (event is! KeyRepeatEvent) unawaited(_toggleFullScreen());
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  // ───────────────────────────── Build ──────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final layout = _layoutOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final panelOpen = _isPanelOpen(layout);
    final isPortrait = layout == _PlayerLayout.portrait;
    final isSplit = layout == _PlayerLayout.split;
    final sideWidth = isSplit ? _kSplitPanelWidth : _kPhonePanelWidth;

    final Widget content = LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final totalHeight = constraints.maxHeight;
        final double stageWidth = isPortrait
            ? totalWidth
            : (totalWidth - (panelOpen ? sideWidth : 0));
        final double stageHeight = isPortrait
            ? (totalWidth * 9 / 16)
            : totalHeight;

        return Stack(
          children: [
            // 📺 INDEX 0 (PERSISTENT): Video stage is NEVER reparented or unmounted across rotation
            Positioned(
              top: 0,
              left: 0,
              width: stageWidth,
              height: stageHeight,
              child: _buildStage(layout, panelOpen: panelOpen),
            ),

            // 📱 PORTRAIT DOUBTS & DETAILS (Under Video)
            if (isPortrait)
              Positioned(
                top: stageHeight,
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  child: Column(
                    children: [
                      _InfoBar(
                        title: widget.title,
                        isDark: isDark,
                        surface: surface,
                      ),
                      _DoubtsTabHeader(isDark: isDark),
                      Expanded(child: DoubtsPanel(key: _doubtsKey)),
                    ],
                  ),
                ),
              ),

            // 💻 LANDSCAPE SIDE PANEL (Immersive & Split)
            if (!isPortrait)
              Positioned(
                top: 0,
                right: 0,
                bottom: 0,
                width: sideWidth,
                child: _buildSidePanel(open: panelOpen, width: sideWidth),
              ),
          ],
        );
      },
    );

    final Widget screen = Scaffold(
      backgroundColor: isPortrait ? surface : Colors.black,
      resizeToAvoidBottomInset: isPortrait,
      body: SafeArea(
        top: isPortrait,
        bottom: false,
        left: false,
        right: false,
        child: content,
      ),
    );

    return PopScope(
      // Back first closes the slide-in doubts panel, then leaves the screen.
      canPop: !(layout == _PlayerLayout.immersive && panelOpen),
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          _restoreSystemChrome();
        } else {
          _setPanelOpen(false);
        }
      },
      child: Focus(
        focusNode: _keyFocus,
        autofocus: true,
        includeSemantics: false,
        onKeyEvent: _onKey,
        child: screen,
      ),
    );
  }

  /// The chat panel stays mounted (just hidden) while closed, so closing it
  /// never throws away what the viewer typed or an answer still loading.
  Widget _buildSidePanel({required bool open, required double width}) {
    return Offstage(
      offstage: !open,
      child: TickerMode(
        enabled: open,
        child: ExcludeFocus(
          excluding: !open,
          child: SizedBox(
            width: width,
            child: _withKeyboardInset(
              _PanelShell(
                onClose: () => _setPanelOpen(false),
                child: DoubtsPanel(key: _doubtsKey),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Makes room for the keyboard without resizing the whole scaffold.
  Widget _withKeyboardInset(Widget child) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: MediaQuery.removeViewInsets(
        context: context,
        removeBottom: true,
        child: child,
      ),
    );
  }

  // ───────────────────────── The video stage ────────────────────────────────

  /// Everything that sits on the video, bottom to top:
  /// player → gestures → status → seek feedback → controls → resume banner.
  Widget _buildStage(_PlayerLayout layout, {required bool panelOpen}) {
    if (kIsWeb) {
      return ColoredBox(
        color: Colors.black,
        child: SizedBox.expand(
          child: getWebYouTubePlayer(
            key: ValueKey('past_web_player_$_videoId'),
            videoId: _videoId,
            isLive: false,
            autoPlay: true,
            title: widget.title,
          ),
        ),
      );
    }

    return ColoredBox(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // IMPORTANT: the only YoutubePlayer in this screen. It is never
          // duplicated per orientation; the GlobalKey moves it between
          // layouts, so rotating neither reloads the video nor resets
          // playback. Do not start playback from YoutubePlayer.onReady (it can
          // fire again when the widget is rebuilt); _maybeStart() does it once.
          Center(
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: RepaintBoundary(
                child: YoutubePlayer(
                  key: _playerKey,
                  controller: _controller,
                  showVideoProgressIndicator: false,
                  bottomActions: const [],
                ),
              ),
            ),
          ),

          // Tap = show / hide controls · double-tap left / right = seek.
          Positioned.fill(
            child: _GestureSurface(
              onTap: _onSurfaceTap,
              onHover: _pokeOverlays,
              onDoubleTapSeek: (forward) =>
                  _seekBy(forward ? _kSeekStep : -_kSeekStep),
            ),
          ),

          // Loading / buffering / error.
          Positioned.fill(
            child: ValueListenableBuilder<_PlaybackUi>(
              valueListenable: _ui,
              builder: (context, ui, _) => ValueListenableBuilder<bool>(
                valueListenable: _slowLoad,
                builder: (context, slow, _) => _StatusLayer(
                  ui: ui,
                  slowLoad: slow,
                  onRetry: _retry,
                ),
              ),
            ),
          ),

          // "« 10 sec" feedback.
          Positioned.fill(
            child: ValueListenableBuilder<_SeekPulse?>(
              valueListenable: _seekPulse,
              builder: (context, pulse, _) => _SeekFeedback(pulse: pulse),
            ),
          ),

          // Controls (fade in / out; not built at all while hidden so they
          // never swallow taps meant for the video).
          Positioned.fill(
            child: ValueListenableBuilder<bool>(
              valueListenable: _overlaysVisible,
              builder: (context, visible, _) => AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: !visible
                    ? const SizedBox.shrink(
                        key: ValueKey<String>('controls-hidden'),
                      )
                    : ValueListenableBuilder<_PlaybackUi>(
                        key: const ValueKey<String>('controls-visible'),
                        valueListenable: _ui,
                        builder: (context, ui, _) => _ControlsOverlay(
                          controller: _controller,
                          ui: ui,
                          layout: layout,
                          title: widget.title,
                          showRotate: _canRotate,
                          showDoubtChip:
                              layout != _PlayerLayout.portrait && !panelOpen,
                          onBack: _goBack,
                          onSpeed: () => unawaited(_showSpeedSheet()),
                          onSeek: _seekBy,
                          onTogglePlay: _togglePlayPause,
                          onRotate: () => unawaited(_toggleFullScreen()),
                          onAskDoubt: () => _setPanelOpen(true),
                        ),
                      ),
              ),
            ),
          ),

          // "Resumed from 12:34 · Start over".
          Positioned.fill(
            child: ValueListenableBuilder<Duration?>(
              valueListenable: _resumeBanner,
              builder: (context, at, _) {
                if (at == null) return const SizedBox.shrink();
                return SafeArea(
                  minimum: const EdgeInsets.all(8),
                  child: Align(
                    alignment: AlignmentDirectional.bottomStart,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 52),
                      child: _ResumeBanner(
                        position: at,
                        onStartOver: _startOver,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Video overlay widgets
// ─────────────────────────────────────────────────────────────────────────────

/// Top bar, centre transport controls and bottom progress bar.
class _ControlsOverlay extends StatelessWidget {
  const _ControlsOverlay({
    required this.controller,
    required this.ui,
    required this.layout,
    required this.title,
    required this.showRotate,
    required this.showDoubtChip,
    required this.onBack,
    required this.onSpeed,
    required this.onSeek,
    required this.onTogglePlay,
    required this.onRotate,
    required this.onAskDoubt,
  });

  final YoutubePlayerController controller;
  final _PlaybackUi ui;
  final _PlayerLayout layout;
  final String title;
  final bool showRotate;
  final bool showDoubtChip;
  final VoidCallback onBack;
  final VoidCallback onSpeed;
  final ValueChanged<Duration> onSeek;
  final VoidCallback onTogglePlay;
  final VoidCallback onRotate;
  final VoidCallback onAskDoubt;

  bool get _portrait => layout == _PlayerLayout.portrait;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Stack(
        children: [
          // The scrim must never absorb taps meant for the video underneath.
          const Positioned.fill(
            child: IgnorePointer(child: DecoratedBox(decoration: _kScrim)),
          ),
          Positioned.fill(
            // Keeps controls clear of notches, cut-outs and the home bar.
            child: SafeArea(
              minimum: const EdgeInsets.fromLTRB(8, 6, 8, 6),
              child: Padding(
                padding: EdgeInsets.only(bottom: _portrait ? 0 : 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTopBar(),
                    Expanded(child: Center(child: _buildCenter())),
                    _buildBottomBar(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        if (!_portrait) ...[
          _OverlayButton(
            icon: Icons.arrow_back_rounded,
            tooltip: 'Back',
            onTap: onBack,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: IgnorePointer(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  shadows: [Shadow(blurRadius: 6, color: Colors.black54)],
                ),
              ),
            ),
          ),
        ] else
          const Spacer(),
        const SizedBox(width: 8),
        _Pill(
          icon: Icons.speed_rounded,
          label: _formatRate(ui.rate),
          tooltip: 'Playback speed',
          onTap: onSpeed,
        ),
      ],
    );
  }

  Widget _buildCenter() {
    if (!ui.isReady || ui.hasError) return const SizedBox.shrink();

    final gap = SizedBox(width: _portrait ? 14 : 36);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _OverlayButton(
          icon: Icons.replay_10_rounded,
          tooltip: 'Back 10 seconds',
          size: 48,
          iconSize: 28,
          onTap: () => onSeek(-_kSeekStep),
        ),
        gap,
        // While buffering, the status layer draws its spinner in this spot.
        if (ui.isBuffering)
          const SizedBox(width: 64, height: 64)
        else
          _PlayPauseButton(ui: ui, onTap: onTogglePlay),
        gap,
        _OverlayButton(
          icon: Icons.forward_10_rounded,
          tooltip: 'Forward 10 seconds',
          size: 48,
          iconSize: 28,
          onTap: () => onSeek(_kSeekStep),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showDoubtChip) ...[
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: _Pill(
              icon: Icons.psychology_alt_outlined,
              label: 'Ask Doubt',
              tooltip: 'Ask an AI doubt about this class',
              background: AppColors.primary,
              onTap: onAskDoubt,
            ),
          ),
          const SizedBox(height: 8),
        ],
        _PlatformPointerInterceptor(
          child: Row(
            children: [
              const SizedBox(width: 6),
              CurrentPosition(controller: controller),
              const SizedBox(width: 8),
              Expanded(
                child: ProgressBar(
                  controller: controller,
                  colors: const ProgressBarColors(
                    playedColor: _kProgressColor,
                    handleColor: _kProgressColor,
                    bufferedColor: Colors.white38,
                    backgroundColor: Colors.white24,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              RemainingDuration(controller: controller),
              if (showRotate) ...[
                const SizedBox(width: 4),
                _OverlayButton(
                  icon: _portrait
                      ? Icons.fullscreen_rounded
                      : Icons.fullscreen_exit_rounded,
                  tooltip: _portrait ? 'Full screen' : 'Exit full screen',
                  size: 40,
                  iconSize: 22,
                  onTap: onRotate,
                ),
              ] else
                const SizedBox(width: 6),
            ],
          ),
        ),
      ],
    );
  }
}

/// Invisible full-size touch layer: tap toggles the controls, double-tap on
/// the left / right half seeks back / forward.
class _GestureSurface extends StatelessWidget {
  const _GestureSurface({
    required this.onTap,
    required this.onHover,
    required this.onDoubleTapSeek,
  });

  final VoidCallback onTap;
  final VoidCallback onHover;
  final ValueChanged<bool> onDoubleTapSeek;

  Widget _half({required bool forward}) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onDoubleTap: () => onDoubleTapSeek(forward),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // PointerInterceptor stops the YouTube iframe from stealing clicks on web;
    // it is a transparent pass-through on mobile / desktop.
    return _PlatformPointerInterceptor(
      child: MouseRegion(
        onHover: (_) => onHover(),
        // Seek direction is physical (left = back) even in RTL locales.
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [_half(forward: false), _half(forward: true)],
          ),
        ),
      ),
    );
  }
}

/// Spinner while loading / buffering, and a friendly retry card on failure.
class _StatusLayer extends StatelessWidget {
  const _StatusLayer({
    required this.ui,
    required this.slowLoad,
    required this.onRetry,
  });

  final _PlaybackUi ui;
  final bool slowLoad;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (ui.hasError) {
      return _FailureView(
        icon: Icons.error_outline_rounded,
        message: _errorMessage(ui.errorCode),
        opaque: true,
        onRetry: onRetry,
      );
    }

    if (!ui.isReady) {
      if (slowLoad) {
        return _FailureView(
          icon: Icons.wifi_off_rounded,
          message: 'This is taking longer than usual. '
              'Check your connection and try again.',
          opaque: false,
          onRetry: onRetry,
        );
      }
      return const _BusySpinner();
    }

    if (ui.isBuffering) return const _BusySpinner();
    return const SizedBox.shrink();
  }
}

class _BusySpinner extends StatelessWidget {
  const _BusySpinner();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: Center(
        child: SizedBox(
          width: 44,
          height: 44,
          child: CircularProgressIndicator(
            strokeWidth: 3.5,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _FailureView extends StatelessWidget {
  const _FailureView({
    required this.icon,
    required this.message,
    required this.onRetry,
    required this.opaque,
  });

  final IconData icon;
  final String message;
  final VoidCallback onRetry;

  /// Errors cover the player completely (hiding YouTube's own error page); the
  /// slow-load card sits on the still-black stage instead.
  final bool opaque;

  @override
  Widget build(BuildContext context) {
    return _PlatformPointerInterceptor(
      child: ColoredBox(
        color: opaque ? Colors.black : Colors.transparent,
        child: Center(
          // Scales down on short portrait players instead of overflowing.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 300),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: Colors.white70, size: 36),
                    const SizedBox(height: 10),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Try again'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "« 10 sec" / "10 sec »" badges shown after a double-tap or key seek.
class _SeekFeedback extends StatelessWidget {
  const _SeekFeedback({required this.pulse});

  final _SeekPulse? pulse;

  Widget _slot(_SeekPulse? shown) {
    return Center(
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 120),
        child: shown == null
            ? const SizedBox.shrink()
            : _SeekBadge(key: ValueKey<int>(shown.seconds), pulse: shown),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = pulse;
    return IgnorePointer(
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          children: [
            Expanded(
              child: _slot(
                current != null && !current.forward ? current : null,
              ),
            ),
            Expanded(
              child: _slot(
                current != null && current.forward ? current : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeekBadge extends StatelessWidget {
  const _SeekBadge({super.key, required this.pulse});

  final _SeekPulse pulse;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _kPillBackground,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              pulse.forward
                  ? Icons.fast_forward_rounded
                  : Icons.fast_rewind_rounded,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: 8),
            Text(
              '${pulse.seconds} sec',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResumeBanner extends StatelessWidget {
  const _ResumeBanner({
    required this.position,
    required this.onStartOver,
  });

  final Duration position;
  final VoidCallback onStartOver;

  @override
  Widget build(BuildContext context) {
    return _PlatformPointerInterceptor(
      child: Material(
        color: const Color(0xE6121212),
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsetsDirectional.only(start: 12, end: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.history_rounded,
                color: Colors.white70,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'Resumed from ${_formatDuration(position)}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              TextButton(
                onPressed: onStartOver,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Start over',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reusable buttons
// ─────────────────────────────────────────────────────────────────────────────

/// Round translucent icon button with tooltip and a proper tap target.
class _OverlayButton extends StatelessWidget {
  const _OverlayButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.size = 44,
    this.iconSize = 24,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return _PlatformPointerInterceptor(
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: _kPillBackground,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(icon, color: Colors.white, size: iconSize),
            ),
          ),
        ),
      ),
    );
  }
}

/// Rounded label button (playback speed, "Ask Doubt").
class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.onTap,
    this.icon,
    this.tooltip,
    this.background = _kPillBackground,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final String? tooltip;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return _PlatformPointerInterceptor(
      child: Tooltip(
        message: tooltip ?? label,
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 36),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayPauseButton extends StatelessWidget {
  const _PlayPauseButton({required this.ui, required this.onTap});

  final _PlaybackUi ui;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final String tooltip;
    if (ui.hasEnded) {
      icon = Icons.replay_rounded;
      tooltip = 'Replay';
    } else if (ui.isPlaying) {
      icon = Icons.pause_rounded;
      tooltip = 'Pause';
    } else {
      icon = Icons.play_arrow_rounded;
      tooltip = 'Play';
    }

    return _OverlayButton(
      icon: icon,
      tooltip: tooltip,
      size: 64,
      iconSize: 40,
      onTap: onTap,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sheets & panel chrome
// ─────────────────────────────────────────────────────────────────────────────

class _SpeedSheet extends StatelessWidget {
  const _SpeedSheet({required this.current});

  final double current;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textDark;

    return _PlatformPointerInterceptor(
      child: SafeArea(
        // Scrolls instead of overflowing on short landscape screens.
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Playback speed',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final rate in _kPlaybackRates)
                      ChoiceChip(
                        label: Text(rate == 1.0 ? 'Normal' : _formatRate(rate)),
                        selected: rate == current,
                        showCheckmark: false,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: rate == current ? Colors.white : textColor,
                        ),
                        onSelected: (_) => Navigator.of(context).pop(rate),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Header + close button + divider around the chat, used by the side panel.
class _PanelShell extends StatelessWidget {
  const _PanelShell({required this.onClose, required this.child});

  final VoidCallback onClose;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.textDark;

    return ColoredBox(
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      child: SafeArea(
        left: false,
        child: Column(
          children: [
            ColoredBox(
              color: Colors.black12,
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 4, 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.psychology_alt_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'AI Doubts',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: onClose,
                      tooltip: 'Close',
                      icon: Icon(
                        Icons.close_rounded,
                        size: 22,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Divider(
              height: 1,
              thickness: 1,
              color: isDark ? Colors.white10 : Colors.black12,
            ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

/// The accent-underlined "Ask AI Doubts" strip under the portrait video.
class _DoubtsTabHeader extends StatelessWidget {
  const _DoubtsTabHeader({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: const Border(
          bottom: BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.psychology_alt_outlined,
            color: AppColors.primary,
            size: 18,
          ),
          SizedBox(width: 8),
          Text(
            'Ask AI Doubts',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Title strip under the video in the tablet / web split layout.
class _InfoBar extends StatelessWidget {
  const _InfoBar({
    required this.title,
    required this.isDark,
    required this.surface,
  });

  final String title;
  final bool isDark;
  final Color surface;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: surface,
      child: SafeArea(
        top: false,
        right: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              const Icon(
                Icons.play_circle_fill_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: isDark ? Colors.white : AppColors.textDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

/// 83 s → "1:23", 3 725 s → "1:02:05".
String _formatDuration(Duration duration) {
  final total = duration.isNegative ? 0 : duration.inSeconds;
  final hours = total ~/ 3600;
  final minutes = (total % 3600) ~/ 60;
  final seconds = (total % 60).toString().padLeft(2, '0');

  if (hours > 0) {
    return '$hours:${minutes.toString().padLeft(2, '0')}:$seconds';
  }
  return '$minutes:$seconds';
}

/// 1.0 → "1×", 1.25 → "1.25×".
String _formatRate(double rate) {
  final text =
      rate == rate.truncateToDouble() ? rate.toInt().toString() : '$rate';
  return '$text×';
}

/// Maps YouTube's embedded-player error codes to something a student can act
/// on.
String _errorMessage(int code) => switch (code) {
      2 => 'This video link looks invalid.',
      5 => 'The player ran into a problem. Please try again.',
      100 => 'This recording was removed or is private.',
      101 || 150 => "This recording can't be played inside the app.",
      _ => 'Something went wrong while loading the recording.',
    };
