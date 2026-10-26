import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/prewarm_service.dart';
import '../utils/app_colors.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pointer_interceptor/pointer_interceptor.dart';
import '../widgets/web_player_loader.dart';
import '../widgets/live_session_panel.dart';
import '../widgets/doubts_panel.dart';
import '../widgets/floating_reactions.dart';
import '../utils/web_fullscreen_helper.dart';
import '../utils/web_navigation_helper.dart';

class LiveClassRoom extends StatefulWidget {
  final String userName;
  final String videoId;
  final String title;
  final bool isAdmin;

  const LiveClassRoom({
    super.key,
    required this.userName,
    required this.videoId,
    required this.title,
    required this.isAdmin,
  });

  @override
  State<LiveClassRoom> createState() => _LiveClassRoomState();
}

class _LiveClassRoomState extends State<LiveClassRoom>
    with WidgetsBindingObserver {
  late final String _videoId;
  late final YoutubePlayerController _playerController;

  // 🚀 SINGLE PERSISTENT KEYS: Keep Player and Panels alive across orientation changes
  final GlobalKey _playerKey = GlobalKey(debugLabel: 'live_youtube_player');
  final GlobalKey _chatKey = GlobalKey(debugLabel: 'live_chat_panel');
  final GlobalKey _doubtsKey = GlobalKey(debugLabel: 'live_doubts_panel');

  bool _isSidePanelOpen = false;
  String _activeTab = 'chat';
  bool _wasLandscape = false;
  bool _showOverlays = true;
  bool _isVideoFirstFrameReady = false;
  bool? _webForceLandscape;
  Timer? _overlayTimer;
  Duration _lastKnownLivePosition = Duration.zero;
  StreamSubscription? _fullscreenSubscription;
  StreamSubscription? _playerBackSub;
  StreamSubscription? _playerSyncSub;
  StreamSubscription? _playerFSSub;
  StreamSubscription? _playerChatSub;
  StreamSubscription? _playerDoubtsSub;
  bool _hasInitializedSidePanel = false;
  bool _isWebPlaying = true;
  bool _isWebMuted = false;

  String get _scheduledTime {
    final title = widget.title;
    final regex = RegExp(r'\(\s*([0-9]{1,2}:[0-9]{2}\s*(?:AM|PM|am|pm))\s*\)');
    final match = regex.firstMatch(title);
    if (match != null) return match.group(1)!;

    final regex2 = RegExp(r'([0-9]{1,2}:[0-9]{2}\s*(?:AM|PM|am|pm))');
    final match2 = regex2.firstMatch(title);
    if (match2 != null) return match2.group(1)!;

    final upcomingTime = AppPrewarmService.instance.upcomingSessionData?['time']?.toString();
    if (upcomingTime != null && upcomingTime.isNotEmpty) return upcomingTime;

    return "Live Broadcast";
  }

  bool _computeIsLandscape(Orientation orientation) {
    if (kIsWeb) {
      final media = MediaQuery.of(context);
      final bool isMobileScreen = media.size.width < 768;
      // 📱 Mobile Web: strictly follow natural device orientation or physical landscape aspect
      if (isMobileScreen) {
        return orientation == Orientation.landscape || media.size.width > media.size.height;
      }
      // 💻 PC / Desktop / Laptop screens with landscape aspect or width >= 768 are ALWAYS landscape:
      if (media.size.width >= 768 && media.size.width > media.size.height) {
        return true;
      }
      if (WebFullscreenHelper.isFullscreen()) return true;
      if (_webForceLandscape != null) {
        return _webForceLandscape!;
      }
      return orientation == Orientation.landscape;
    }
    return orientation == Orientation.landscape;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Sanitize video ID from any YouTube URL format (youtu.be, shorts, /watch?v=)
    _videoId = YoutubePlayer.convertUrlToId(widget.videoId) ?? widget.videoId;

    // ⚡ SUB-50MS INSTANT START: Check if controller was pre-warmed in background
    final prewarmed = AppPrewarmService.instance.prewarmedPlayerController;
    if (prewarmed != null && AppPrewarmService.instance.currentVideoId == _videoId) {
      _playerController = prewarmed;
    } else {
      _playerController = YoutubePlayerController(
        initialVideoId: _videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          isLive: true,
          forceHD: false,
          mute: false,
          hideControls: true,
          disableDragSeek: false,
          enableCaption: false,
          useHybridComposition: false, // ⚡ FAST INITIALIZATION: Texture view initializes in <300ms without Hybrid Composition surface lag
        ),
      );
    }
    // ⚡ INSTANT PLAYBACK & POSITION RECOVERY
    _playerController.addListener(_onPlayerStateChanged);

    // 💡 KEEP SCREEN ON: Prevents screen from sleeping/locking while watching live class
    try {
      WakelockPlus.enable();
    } catch (_) {}

    if (!kIsWeb) {
      // 🔄 PERMIT NATURAL ROTATION: Allow phone auto-rotation seamlessly
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      WebNavigationHelper.updateUrl('/live?v=$_videoId');
      _fullscreenSubscription = WebFullscreenHelper.listenFullscreenChange((isFs) {
        if (mounted) {
          setState(() {
            _webForceLandscape = isFs ? true : null;
          });
        }
      });
      _playerBackSub = WebFullscreenHelper.listenPlayerBack(() {
        if (mounted) {
          if (WebFullscreenHelper.isFullscreen()) {
            WebFullscreenHelper.exitFullscreen();
          }
          _registerAttendance(false);
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            Navigator.pushReplacementNamed(context, '/home');
          }
        }
      });
      _playerSyncSub = WebFullscreenHelper.listenPlayerSync(() {
        if (mounted) _syncToLive();
      });
      _playerFSSub = WebFullscreenHelper.listenPlayerFullscreen(() {
        if (mounted) {
          setState(() {
            _webForceLandscape = WebFullscreenHelper.isFullscreen() ? true : null;
          });
        }
      });
      _playerChatSub = WebFullscreenHelper.listenPlayerChat(() {
        if (mounted) {
          setState(() {
            if (_isSidePanelOpen && _activeTab == 'chat') {
              _isSidePanelOpen = false;
            } else {
              _isSidePanelOpen = true;
              _activeTab = 'chat';
            }
          });
        }
      });
      _playerDoubtsSub = WebFullscreenHelper.listenPlayerDoubts(() {
        if (mounted) {
          setState(() {
            if (_isSidePanelOpen && _activeTab == 'doubts') {
              _isSidePanelOpen = false;
            } else {
              _isSidePanelOpen = true;
              _activeTab = 'doubts';
            }
          });
        }
      });
    }

    _registerAttendance(true);
    _startOverlayTimer();
  }

  void _onPlayerStateChanged() {
    final currentPos = _playerController.value.position;
    if (currentPos > Duration.zero) {
      _lastKnownLivePosition = currentPos;
    }
    if (_playerController.value.isPlaying || _playerController.value.position > Duration.zero) {
      if (!_isVideoFirstFrameReady && mounted) {
        setState(() => _isVideoFirstFrameReady = true);
      }
    }
    if (_playerController.value.isReady &&
        !_playerController.value.isPlaying &&
        !_playerController.value.hasError) {
      _playerController.play();
      if (!_isVideoFirstFrameReady && mounted) {
        setState(() => _isVideoFirstFrameReady = true);
      }
      if (_lastKnownLivePosition > const Duration(seconds: 3) &&
          _playerController.value.position < const Duration(seconds: 1)) {
        _playerController.seekTo(_lastKnownLivePosition);
      }
    }
  }

  @override
  void dispose() {
    try {
      WakelockPlus.disable();
    } catch (_) {}
    if (kIsWeb) {
      WebNavigationHelper.updateUrl('/home');
    }
    _registerAttendance(false);
    WidgetsBinding.instance.removeObserver(this);
    _overlayTimer?.cancel();
    _playerController.removeListener(_onPlayerStateChanged);
    _playerController.pause();
    if (_playerController == AppPrewarmService.instance.prewarmedPlayerController) {
      AppPrewarmService.instance.invalidatePrewarmedController();
    }
    _playerController.dispose();

    if (!kIsWeb) {
      // 🔄 RESTORE ORIENTATIONS: Ensure all device orientations remain responsive
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } else {
      _fullscreenSubscription?.cancel();
      _playerBackSub?.cancel();
      _playerSyncSub?.cancel();
      _playerFSSub?.cancel();
      _playerChatSub?.cancel();
      _playerDoubtsSub?.cancel();
      if (WebFullscreenHelper.isFullscreen()) {
        WebFullscreenHelper.exitFullscreen();
      }
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _registerAttendance(false);
    } else if (state == AppLifecycleState.resumed) {
      _registerAttendance(true);
    }
  }

  void _registerAttendance(bool isEntering) {
    if (widget.isAdmin) return;
    try {
      final doc =
          FirebaseFirestore.instance.collection('live_session').doc('current');
      if (isEntering) {
        doc.set({
          'active_viewers': FieldValue.arrayUnion([widget.userName])
        }, SetOptions(merge: true)).catchError((e) {
          debugPrint("Attendance registration error: $e");
        });
      } else {
        doc.set({
          'active_viewers': FieldValue.arrayRemove([widget.userName])
        }, SetOptions(merge: true)).catchError((e) {
          debugPrint("Attendance removal error: $e");
        });
      }
    } catch (e) {
      debugPrint("Attendance error: $e");
    }
  }

  void _toggleOverlays() {
    if (!mounted) return;
    setState(() => _showOverlays = !_showOverlays);
    if (_showOverlays) _startOverlayTimer();
  }

  void _startOverlayTimer() {
    _overlayTimer?.cancel();
    _overlayTimer = Timer(const Duration(milliseconds: 3500), () {
      if (mounted && _showOverlays) setState(() => _showOverlays = false);
    });
  }

  void _toggleFullScreen() {
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = _computeIsLandscape(orientation);
    try {
      if (!kIsWeb) HapticFeedback.lightImpact();
    } catch (_) {}

    if (kIsWeb) {
      final isCurrentlyFs = WebFullscreenHelper.isFullscreen();
      if (isCurrentlyFs) {
        WebFullscreenHelper.exitFullscreen();
        setState(() {
          _webForceLandscape = null;
        });
      } else {
        WebFullscreenHelper.enterFullscreen();
        setState(() {
          _webForceLandscape = true;
        });
      }
    } else {
      if (isLandscape) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
      } else {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      }
    }
    _startOverlayTimer();
  }

  void _toggleWebPlayPause() {
    setState(() {
      _isWebPlaying = !_isWebPlaying;
    });
    WebFullscreenHelper.sendVideoCommand(_isWebPlaying ? 'playVideo' : 'pauseVideo');
    _startOverlayTimer();
  }

  void _toggleWebMute() {
    setState(() {
      _isWebMuted = !_isWebMuted;
    });
    WebFullscreenHelper.sendVideoCommand(_isWebMuted ? 'mute' : 'unMute');
    _startOverlayTimer();
  }

  bool get _isTypingInTextField {
    final focusContext = FocusManager.instance.primaryFocus?.context;
    if (focusContext != null) {
      if (focusContext.widget is EditableText ||
          focusContext.findAncestorWidgetOfExactType<EditableText>() != null ||
          focusContext.findAncestorWidgetOfExactType<TextField>() != null) {
        return true;
      }
    }
    final focusNode = FocusManager.instance.primaryFocus;
    if (focusNode != null) {
      final label = focusNode.debugLabel?.toLowerCase() ?? '';
      if (label.contains('editable') ||
          label.contains('text') ||
          label.contains('chat') ||
          label.contains('doubt') ||
          label.contains('input')) {
        return true;
      }
    }
    return false;
  }

  void _syncToLive() {
    try {
      if (!kIsWeb) HapticFeedback.mediumImpact();
    } catch (_) {}
    if (kIsWeb) {
      WebFullscreenHelper.sendVideoCommand('seekTo', [999999, true]);
    } else {
      _playerController.load(_videoId);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.bolt_rounded, color: AppColors.accent, size: 18),
            SizedBox(width: 8),
            Text("Synced to Realtime Live Edge!"),
          ],
        ),
        backgroundColor: Color(0xFF0F172A),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
    _startOverlayTimer();
  }

  Widget _buildCustomControls(bool isLandscape) {
    return Positioned(
      bottom: isLandscape ? 32 : 12,
      left: 16,
      right: isLandscape ? 16 : 55,
      child: Row(
        children: [
          const Icon(Icons.circle, color: Colors.red, size: 10)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .fade(duration: 800.ms),
          const SizedBox(width: 6),
          const Text(
            "LIVE",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 13,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: ProgressBar(
              controller: _playerController,
              isExpanded: true,
              colors: const ProgressBarColors(
                playedColor: Colors.red,
                handleColor: Colors.red,
                bufferedColor: Colors.white30,
                backgroundColor: Colors.white24,
              ),
            ),
          ),
        ],
      ).animate().fadeIn(duration: 200.ms),
    );
  }

  // 📺 UNIFIED VIDEO STAGE: Preserves YoutubePlayer element across rotation
  Widget _buildVideoStage(bool isLandscape) {
    if (kIsWeb) {
      return ColoredBox(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            getWebYouTubePlayer(
              key: ValueKey('live_web_player_$_videoId'),
              videoId: _videoId,
              isLive: true,
              autoPlay: true,
              title: widget.title,
            ),
            // 🎈 Floating Reactions Layer for instantaneous local and remote emoji bubbles
            const Positioned.fill(
              child: IgnorePointer(
                child: FloatingReactionsLayer(),
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      fit: isLandscape ? StackFit.expand : StackFit.loose,
      children: [
        Center(
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: RepaintBoundary(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  YoutubePlayer(
                    key: _playerKey,
                    controller: _playerController,
                    showVideoProgressIndicator: false,
                    bottomActions: const [],
                    onReady: () {
                      _playerController.play();
                      if (!_isVideoFirstFrameReady && mounted) {
                        setState(() => _isVideoFirstFrameReady = true);
                      }
                    },
                  ),
                  // ⚡ INSTANT THUMBNAIL BACKDROP (Like YouTube app)
                  // Displays the pre-cached HD thumbnail with YouTube Premiere countdown badge
                  if (!_isVideoFirstFrameReady)
                    Positioned.fill(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CachedNetworkImage(
                            imageUrl: "https://img.youtube.com/vi/$_videoId/maxresdefault.jpg",
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => CachedNetworkImage(
                              imageUrl: "https://img.youtube.com/vi/$_videoId/hqdefault.jpg",
                              fit: BoxFit.cover,
                            ),
                          ),
                          Container(
                            color: Colors.black.withValues(alpha: 0.45),
                            child: Stack(
                              children: [
                                // Center Live Premiere Alert
                                Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.82),
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(color: AppColors.liveRed, width: 1.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.liveRed.withValues(alpha: 0.4),
                                          blurRadius: 16,
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.circle, color: AppColors.liveRed, size: 10)
                                            .animate(onPlay: (c) => c.repeat(reverse: true))
                                            .fade(duration: 600.ms),
                                        const SizedBox(width: 8),
                                        Text(
                                          "PREMIERE • $_scheduledTime",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 12,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Bottom-Left YouTube-style Scheduled Time badge
                                Positioned(
                                  bottom: 12,
                                  left: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.85),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.sensors_rounded, color: Colors.redAccent, size: 14),
                                        const SizedBox(width: 6),
                                        Text(
                                          "Starts at $_scheduledTime",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Bottom-Right Waiting Room Status
                                Positioned(
                                  bottom: 12,
                                  right: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.85),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        width: 1,
                                      ),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.chat_bubble_outline_rounded, color: AppColors.accent, size: 12),
                                        SizedBox(width: 5),
                                        Text(
                                          "Live Chat Ready",
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        // 🎈 Floating Reactions Layer: Live reactions float upwards across the video stage
        const Positioned.fill(
          child: IgnorePointer(
            child: FloatingReactionsLayer(),
          ),
        ),
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _toggleOverlays,
            child: Container(color: Colors.transparent),
          ),
        ),
        if (_showOverlays) ...[
          _buildCustomControls(isLandscape),
          // Back Button Overlay - ONLY in Portrait mode! (Removed in landscape per user request)
          if (!isLandscape)
            Positioned(
              top: 12,
              left: 12,
              child: InkWell(
                onTap: () {
                  _registerAttendance(false);
                  Navigator.pop(context);
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 16),
                ),
              ),
            ),
          if (isLandscape) ...[
            // Exit Fullscreen Button - shifted to left: 14 because back button is hidden in landscape
            Positioned(
              top: 14,
              left: 14,
              child: InkWell(
                onTap: _toggleFullScreen,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.fullscreen_exit_rounded,
                          color: Colors.white, size: 18),
                      SizedBox(width: 6),
                      Text(
                        "Exit Fullscreen",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 200.ms),
            ),
            // Sync Live Button (Landscape)
            if (!widget.isAdmin)
              Positioned(
                top: 16,
                right: 16,
                child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.sync_rounded,
                        size: 16, color: Colors.white),
                    label: const Text(
                      "SYNC LIVE",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    onPressed: _syncToLive,
                  ).animate().fadeIn(duration: 200.ms),
              ),
            // Floating Quick Action Pills
            Positioned(
              bottom: 64,
              right: 16,
              child: Row(
                children: [
                  _buildOverlayBtn(
                    Icons.chat_bubble_outline_rounded,
                    "Chat",
                    () {
                      setState(() {
                        _isSidePanelOpen = true;
                        _activeTab = 'chat';
                        _showOverlays = false;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildOverlayBtn(
                    Icons.psychology_alt_outlined,
                    "Doubts",
                    () {
                      setState(() {
                        _isSidePanelOpen = true;
                        _activeTab = 'doubts';
                        _showOverlays = false;
                      });
                    },
                  ),
                ],
              ).animate().fadeIn(duration: 200.ms),
            ),
          ] else ...[
            // Fullscreen Button (Portrait)
            Positioned(
              bottom: 8,
              right: 8,
              child: InkWell(
                onTap: _toggleFullScreen,
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.fullscreen_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ).animate().fadeIn(duration: 200.ms),
            ),
          ],
        ],
      ],
    );
  }

  // 💬 STATE-PRESERVING PANELS: Kept alive so scroll & messages never reset
  Widget _buildPanelsContent() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: IndexedStack(
        index: _activeTab == 'chat' ? 0 : 1,
        children: [
          LiveSessionPanel(
            key: _chatKey,
            userName: widget.userName,
            isAdmin: widget.isAdmin,
          ),
          DoubtsPanel(key: _doubtsKey),
        ],
      ),
    );
  }

  Widget _buildPortraitInfoAndTabs() {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bool isKeyboardOpen = bottomInset > 80;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: Column(
        children: [
        // Class Info Row (Auto-collapses when virtual keyboard is open to preserve chat space)
        if (!isKeyboardOpen)
          Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF162544),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withValues(alpha: 0.12),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              RepaintBoundary(
                child: const Icon(Icons.circle,
                        color: AppColors.error, size: 8)
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .fade(duration: 800.ms),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!widget.isAdmin)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _syncToLive,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary
                            .withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.accent
                              .withValues(alpha: 0.40),
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.sync_rounded,
                              color: AppColors.accent, size: 14),
                          SizedBox(width: 4),
                          Text(
                            "Sync Live",
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Liquid Tabs (Live Chat / Ask Doubts)
        Container(
          color: const Color(0xFF162544),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () =>
                      setState(() => _activeTab = 'chat'),
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(vertical: isKeyboardOpen ? 7 : 11),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: _activeTab == 'chat'
                              ? AppColors.accent
                              : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.chat_bubble_rounded,
                            size: 15,
                            color: _activeTab == 'chat'
                                ? AppColors.accent
                                : Colors.white38,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Live Chat",
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: _activeTab == 'chat'
                                  ? Colors.white
                                  : Colors.white38,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () =>
                      setState(() => _activeTab = 'doubts'),
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(vertical: isKeyboardOpen ? 7 : 11),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: _activeTab == 'doubts'
                              ? AppColors.accent
                              : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.psychology_rounded,
                            size: 16,
                            color: _activeTab == 'doubts'
                                ? AppColors.accent
                                : Colors.white38,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "AI Doubts",
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: _activeTab == 'doubts'
                                  ? Colors.white
                                  : Colors.white38,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Persistent Content
        Expanded(child: _buildPanelsContent()),
      ],
    ),
  );
}

  Widget _buildLandscapeSidePanel({double width = 360}) {
    return Container(
      width: width,
      decoration: const BoxDecoration(
        color: Color(0xFF162544),
        border: Border(
          left: BorderSide(color: Colors.white12, width: 1),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            color: Colors.black26,
            child: Row(
              children: [
                _buildSidePanelTab('chat', Icons.chat_rounded, "Live Chat", "C"),
                const SizedBox(width: 6),
                _buildSidePanelTab('doubts', Icons.psychology_rounded, "AI Doubts", "D"),
                const Spacer(),
                // Real-time Classmates Live Viewers Pill
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('live_session')
                      .doc('current')
                      .snapshots(),
                  builder: (context, snapshot) {
                    int count = 1;
                    if (snapshot.hasData && snapshot.data!.exists) {
                      final data = snapshot.data!.data() as Map<String, dynamic>?;
                      final viewers = data?['active_viewers'] as List?;
                      if (viewers != null && viewers.isNotEmpty) {
                        count = viewers.length;
                      }
                    }
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4), width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.circle, size: 6, color: Colors.redAccent),
                          const SizedBox(width: 4),
                          Text(
                            "$count live",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 19, color: Colors.white70),
                  onPressed: () => setState(() => _isSidePanelOpen = false),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: "Collapse Panel (C / D)",
                ),
              ],
            ),
          ),
          const Divider(
              height: 1,
              thickness: 1,
              color: Colors.white10),
          Expanded(child: _buildPanelsContent()),
        ],
      ),
    );
  }

  Widget _buildSidePanelTab(String tab, IconData icon, String label, [String? shortcut]) {
    final bool isSelected = _activeTab == tab;
    return InkWell(
      onTap: () {
        if (_activeTab != tab) {
          setState(() => _activeTab = tab);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent.withValues(alpha: 0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.accent.withValues(alpha: 0.5) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? AppColors.accent : Colors.white60,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : Colors.white70,
              ),
            ),
            if (shortcut != null) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0.5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  shortcut,
                  style: TextStyle(
                    fontSize: 8.5,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white70 : Colors.white38,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        final bool isLandscape = _computeIsLandscape(orientation);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!kIsWeb) {
            if (isLandscape && !_wasLandscape) {
              SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
              _wasLandscape = true;
            } else if (!isLandscape && _wasLandscape) {
              SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
              _wasLandscape = false;
            }
          }
        });

        return PopScope(
          canPop: !isLandscape,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) {
              _registerAttendance(false);
            } else if (isLandscape) {
              // 📱 Shift from landscape back to portrait without exiting live class
              _toggleFullScreen();
            }
          },
          child: Focus(
            autofocus: true,
            onKeyEvent: (node, event) {
              if (event is KeyUpEvent || _isTypingInTextField) {
                return KeyEventResult.ignored;
              }
              if (event is KeyDownEvent) {
                if (kIsWeb) {
                  // On Web, native HTML window onKeyDown handles K, M, Space, F, etc.
                  // directly on the player with visual feedback and zero conflict.
                  if (event.logicalKey == LogicalKeyboardKey.escape &&
                      WebFullscreenHelper.isFullscreen()) {
                    WebFullscreenHelper.exitFullscreen();
                    setState(() => _webForceLandscape = null);
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                }
                if (event.logicalKey == LogicalKeyboardKey.space ||
                    event.logicalKey == LogicalKeyboardKey.keyK) {
                  _toggleWebPlayPause();
                  return KeyEventResult.handled;
                }
                if (event.logicalKey == LogicalKeyboardKey.keyF) {
                  _toggleFullScreen();
                  return KeyEventResult.handled;
                }
                if (event.logicalKey == LogicalKeyboardKey.keyM) {
                  _toggleWebMute();
                  return KeyEventResult.handled;
                }
              }
              return KeyEventResult.ignored;
            },
            child: Scaffold(
              backgroundColor: isLandscape ? Colors.black : const Color(0xFF0F172A),
              resizeToAvoidBottomInset: true,
              body: SafeArea(
              top: !isLandscape,
              bottom: !isLandscape,
              left: false,
              right: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final totalWidth = constraints.maxWidth;
                  final totalHeight = constraints.maxHeight;
                  if (!_hasInitializedSidePanel) {
                    _hasInitializedSidePanel = true;
                    if (totalWidth >= 1050) {
                      _isSidePanelOpen = true;
                    }
                  }

                  // Responsive side panel width
                  final double sidePanelWidth = (totalWidth * 0.28).clamp(300.0, 380.0);
                  final bool useSideBySide = isLandscape && totalWidth >= 900;

                  final double videoHeight = isLandscape ? totalHeight : (totalWidth * 9 / 16);
                  final double videoWidth = isLandscape
                      ? (useSideBySide && _isSidePanelOpen ? (totalWidth - sidePanelWidth) : totalWidth)
                      : totalWidth;

                  return Stack(
                    children: [
                      // 📺 INDEX 0 (PERSISTENT): Video stage is NEVER unmounted across orientation changes
                      Positioned(
                        top: 0,
                        left: 0,
                        width: videoWidth,
                        height: videoHeight,
                        child: _buildVideoStage(isLandscape),
                      ),

                      // 📱 PORTRAIT CONTENT (Under Video)
                      if (!isLandscape)
                        Positioned(
                          top: videoHeight,
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: _buildPortraitInfoAndTabs(),
                        ),

                      // 💻 LANDSCAPE SIDE PANEL: Side-by-side on wide screens (>=900px)
                      if (isLandscape && useSideBySide)
                        Positioned(
                          top: 0,
                          right: 0,
                          bottom: 0,
                          width: sidePanelWidth,
                          child: Offstage(
                            offstage: !_isSidePanelOpen,
                            child: _buildLandscapeSidePanel(width: sidePanelWidth),
                          ),
                        ),

                      // 💻 PC/DESKTOP QUICK SIDEBAR RESTORE DOCK TAB
                      if (isLandscape && useSideBySide && !_isSidePanelOpen)
                        Positioned(
                          top: 18,
                          right: 18,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => setState(() => _isSidePanelOpen = true),
                              borderRadius: BorderRadius.circular(24),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F172A).withValues(alpha: 0.88),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: AppColors.accent.withValues(alpha: 0.45),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.5),
                                      blurRadius: 14,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.chat_bubble_rounded,
                                      color: AppColors.accent,
                                      size: 15,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      "Live Chat",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Colors.greenAccent,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ).animate().fadeIn(duration: 250.ms),
                        ),

                      // 💻 LANDSCAPE FLOATING DRAWER PANEL: Overlay on compact screens (<900px) so video is NEVER crushed or cut!
                      if (isLandscape && !useSideBySide && _isSidePanelOpen) ...[
                        Positioned.fill(
                          child: PointerInterceptor(
                            child: GestureDetector(
                              onTap: () => setState(() => _isSidePanelOpen = false),
                              child: Container(
                                color: Colors.black45,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          bottom: 0,
                          width: (totalWidth * 0.65).clamp(280.0, 360.0),
                          child: PointerInterceptor(
                            child: Material(
                              elevation: 16,
                              color: Colors.transparent,
                              child: _buildLandscapeSidePanel(
                                width: (totalWidth * 0.65).clamp(280.0, 360.0),
                              ),
                            ),
                          ),
                        ),
                      ],

                      // 📱 MOBILE WEB LANDSCAPE QUICK ACTION PILLS (Thumb reachable on right side)
                      if (isLandscape && !useSideBySide && !_isSidePanelOpen)
                        Positioned(
                          bottom: 24,
                          right: 16,
                          child: PointerInterceptor(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildOverlayBtn(
                                  Icons.chat_bubble_outline_rounded,
                                  "Chat",
                                  () {
                                    setState(() {
                                      _isSidePanelOpen = true;
                                      _activeTab = 'chat';
                                    });
                                  },
                                ),
                                const SizedBox(width: 8),
                                _buildOverlayBtn(
                                  Icons.psychology_alt_outlined,
                                  "Doubts",
                                  () {
                                    setState(() {
                                      _isSidePanelOpen = true;
                                      _activeTab = 'doubts';
                                    });
                                  },
                                ),
                              ],
                            ).animate().fadeIn(duration: 250.ms),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );
      },
    );
  }

  Widget _buildOverlayBtn(IconData icon, String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
