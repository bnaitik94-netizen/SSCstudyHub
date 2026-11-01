import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';

class LiveClassPreloadEngine extends ChangeNotifier {
  static final LiveClassPreloadEngine _instance = LiveClassPreloadEngine._internal();
  factory LiveClassPreloadEngine() => _instance;
  LiveClassPreloadEngine._internal();

  // ── Cached Student Identity ──
  String _cachedStudentName = "SSC Student";
  String _cachedStudentEmail = "student@sscstudyhub.in";

  // ── Cached Stream & Class Data ──
  bool _isClassLive = false;
  String _subject = "Class 10 Live Lecture";
  String _topic = "Board Exam Prep";
  String _rawYoutubeUrl = "";
  String? _parsedYoutubeVideoId;
  bool _isYoutubeLiveStream = true;

  String _rawJitsiUrl = "";
  String _parsedJitsiRoomName = "";
  String _parsedJitsiServerUrl = "https://meet.jit.si";

  // ── Pre-Loaded Readiness States ──
  bool _permissionsGranted = false;
  bool _isJitsiPreloaded = false;
  bool _isYoutubePrewarmed = false;

  // ── Pre-Built Instances ──
  JitsiMeetConferenceOptions? _jitsiConferenceOptions;
  YoutubePlayerController? _youtubeController;
  StreamSubscription<DocumentSnapshot>? _firestoreSubscription;

  // ── Getters ──
  String get cachedStudentName => _cachedStudentName;
  String get cachedStudentEmail => _cachedStudentEmail;
  bool get isClassLive => _isClassLive;
  String get subject => _subject;
  String get topic => _topic;
  String? get parsedYoutubeVideoId => _parsedYoutubeVideoId;
  String get parsedJitsiRoomName => _parsedJitsiRoomName;
  String get parsedJitsiServerUrl => _parsedJitsiServerUrl;
  bool get permissionsGranted => _permissionsGranted;
  bool get isJitsiPreloaded => _isJitsiPreloaded;
  bool get isYoutubePrewarmed => _isYoutubePrewarmed;
  bool get isReadyForInstantLaunch => _isClassLive && (_isJitsiPreloaded || _isYoutubePrewarmed);
  JitsiMeetConferenceOptions? get jitsiConferenceOptions => _jitsiConferenceOptions;
  YoutubePlayerController? get youtubeController => _youtubeController;

  /// Initializes all pre-loaders immediately on app open
  Future<void> initialize() async {
    await _preloadStudentIdentity();
    await _checkAndPreloadPermissions();
    _startFirestoreLiveListener();
  }

  /// Step A: Pre-load and check camera/microphone permissions
  Future<void> _checkAndPreloadPermissions() async {
    if (kIsWeb) {
      _permissionsGranted = true;
      notifyListeners();
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final bool? cachedPerm = prefs.getBool('cached_camera_mic_permission');
      if (cachedPerm == true) {
        _permissionsGranted = true;
      }

      final camStatus = await Permission.camera.status;
      final micStatus = await Permission.microphone.status;

      if (!camStatus.isGranted || !micStatus.isGranted) {
        final Map<Permission, PermissionStatus> statuses = await [
          Permission.camera,
          Permission.microphone,
        ].request();

        _permissionsGranted = (statuses[Permission.camera]?.isGranted ?? false) &&
            (statuses[Permission.microphone]?.isGranted ?? false);
      } else {
        _permissionsGranted = true;
      }

      await prefs.setBool('cached_camera_mic_permission', _permissionsGranted);
      notifyListeners();
    } catch (e) {
      debugPrint("Preload Permissions Warning: $e");
    }
  }

  /// Step B: Pre-load registered student name and email into RAM
  Future<void> _preloadStudentIdentity() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user?.displayName != null && user!.displayName!.trim().isNotEmpty) {
        _cachedStudentName = user.displayName!.trim();
        _cachedStudentEmail = user.email ?? "student@sscstudyhub.in";
      } else {
        final prefs = await SharedPreferences.getInstance();
        final storedName = prefs.getString('student_name') ?? prefs.getString('user_name');
        if (storedName != null && storedName.trim().isNotEmpty) {
          _cachedStudentName = storedName.trim();
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Student Identity Preload Warning: $e");
    }
  }

  /// Step C: Persistent Real-time Firestore Listener on live_lectures/current_live
  void _startFirestoreLiveListener() {
    _firestoreSubscription?.cancel();
    _firestoreSubscription = FirebaseFirestore.instance
        .collection('live_lectures')
        .doc('current_live')
        .snapshots()
        .listen(
      (doc) {
        if (!doc.exists) {
          _isClassLive = false;
          _cleanupEngines();
          notifyListeners();
          return;
        }

        final data = doc.data() as Map<String, dynamic>;
        _isClassLive = data['is_live'] == true;
        _subject = data['subject'] ?? "Maharashtra SSC Class 10";
        _topic = data['topic'] ?? "Live Lecture";
        _rawYoutubeUrl = data['youtube_url'] ?? "";
        _rawJitsiUrl = data['jitsi_room_name'] ?? "";
        _isYoutubeLiveStream = data['is_youtube_live'] ?? true;

        if (_isClassLive) {
          _parseAndPrebuildJitsi(_rawJitsiUrl);
          _parseAndPrewarmYoutube(_rawYoutubeUrl);
        } else {
          _cleanupEngines();
        }
        notifyListeners();
      },
      onError: (err) {
        debugPrint("Firestore Live Class Stream Error: $err");
      },
    );
  }

  /// Step D: Parse Jitsi URL/Room and Pre-build Conference Options in RAM
  void _parseAndPrebuildJitsi(String rawInput) {
    if (rawInput.trim().isEmpty) {
      _isJitsiPreloaded = false;
      _jitsiConferenceOptions = null;
      return;
    }

    String cleanRoom = rawInput.trim();
    String serverUrl = "https://meet.jit.si";

    if (cleanRoom.startsWith("http://") || cleanRoom.startsWith("https://")) {
      final uri = Uri.tryParse(cleanRoom);
      if (uri != null) {
        serverUrl = "${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}";
        cleanRoom = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : "SSC_Live_Room";
      }
    }

    // Clean special characters
    cleanRoom = cleanRoom.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
    _parsedJitsiRoomName = cleanRoom;
    _parsedJitsiServerUrl = serverUrl;

    // Build zero-friction conference options with pre-warmed name and mute flags
    _jitsiConferenceOptions = JitsiMeetConferenceOptions(
      serverURL: _parsedJitsiServerUrl,
      room: _parsedJitsiRoomName,
      userInfo: JitsiMeetUserInfo(
        displayName: _cachedStudentName,
        email: _cachedStudentEmail,
      ),
      configOverrides: {
        'prejoinPageEnabled': false, // NO NAME ENTRY LOBBY PROMPT
        'startWithAudioMuted': true,
        'startWithVideoMuted': true,
        'disableDeepLinking': true,
        'resolution': 720,           // FULL HD 720p/1080p LOCKED QUALITY
        'channelLastN': 2,           // ZERO MULTI-STREAM LAG (ONLY TEACHER STREAM DECODED)
        'disableTileView': true,
        'disableBlur': true,
      },
      featureFlags: {
        'invite.enabled': false,
        'pip.enabled': true,
        'chat.enabled': true,
        'raise-hand.enabled': true,
        'welcomepage.enabled': false,
      },
    );

    _isJitsiPreloaded = true;
  }

  /// Step E: Parse YouTube link & Pre-warm Video Controller in RAM
  void _parseAndPrewarmYoutube(String rawUrl) {
    if (rawUrl.trim().isEmpty) {
      _isYoutubePrewarmed = false;
      _youtubeController?.dispose();
      _youtubeController = null;
      return;
    }

    final String? videoId = YoutubePlayer.convertUrlToId(rawUrl.trim());
    if (videoId == null || videoId.isEmpty) {
      _isYoutubePrewarmed = false;
      return;
    }

    // Reuse existing controller if the video ID has not changed
    if (_parsedYoutubeVideoId == videoId && _youtubeController != null) {
      _isYoutubePrewarmed = true;
      return;
    }

    _parsedYoutubeVideoId = videoId;
    _youtubeController?.dispose();

    _youtubeController = YoutubePlayerController(
      initialVideoId: videoId,
      flags: YoutubePlayerFlags(
        autoPlay: false, // Pre-warmed silently; play() is called upon view entry
        mute: false,
        isLive: _isYoutubeLiveStream,
        forceHD: true,   // Full HD whiteboard/text clarity
        enableCaption: false,
        showLiveFullscreenButton: true,
      ),
    );

    _isYoutubePrewarmed = true;
  }

  void _cleanupEngines() {
    _isJitsiPreloaded = false;
    _isYoutubePrewarmed = false;
    _jitsiConferenceOptions = null;
    _youtubeController?.dispose();
    _youtubeController = null;
  }

  /// Shows glassmorphic settings dialog if camera/mic permissions were permanently denied
  void promptPermissionSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF111827),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.white24),
        ),
        title: const Text(
          "Camera & Mic Required",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "To join interactive audio/video classes, please grant camera and microphone access in App Settings.",
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00F2FE)),
            child: const Text("Open Settings", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _firestoreSubscription?.cancel();
    _cleanupEngines();
    super.dispose();
  }
}
