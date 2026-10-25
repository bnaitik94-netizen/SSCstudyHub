// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/web_fullscreen_helper.dart';

final Set<String> _registeredViewTypes = {};

const String _kPlayerCss = '''
    .cinematic-player-wrapper {
        position: relative; 
        width: 100%; 
        height: 100%;
        background: #000000; 
        overflow: hidden; 
        display: flex; 
        align-items: center; 
        justify-content: center; 
        transition: all 0.25s ease;
        box-sizing: border-box;
        user-select: none;
        -webkit-user-select: none;
        container-type: inline-size;
        container-name: player;
    }

    .youtube-iframe { 
        position: absolute;
        top: 0;
        left: 0;
        width: 100%; 
        height: 100%; 
        border: none; 
        display: block; 
        pointer-events: none !important; /* 🛡️ Bulletproof: YouTube NEVER receives pointer events */
    }

    /* 🌟 THE TOUCH & POINTER INTERCEPTOR: Catches 100% of mouse moves and clicks */
    .touch-interceptor {
        position: absolute; 
        inset: 0; 
        width: 100%;
        height: 100%;
        z-index: 20;
        background: transparent; 
        cursor: default; /* 🛡️ Standard clean arrow pointer over video stage */
        pointer-events: auto;
        user-select: none;
        -webkit-user-select: none;
    }

    /* 🎈 FLOATING EMOJI REACTIONS OVERLAY (Right Side of Screen) */
    .web-floating-reactions {
        position: absolute;
        inset: 0;
        z-index: 25;
        pointer-events: none;
        overflow: hidden;
    }

    .floating-emoji-item {
        position: absolute;
        bottom: 30px;
        font-size: 36px;
        user-select: none;
        pointer-events: none;
        animation: webFloatUpRight 2.6s cubic-bezier(0.22, 1, 0.36, 1) forwards;
        filter: drop-shadow(0 4px 12px rgba(0, 0, 0, 0.6));
    }

    @keyframes webFloatUpRight {
        0% {
            opacity: 0;
            transform: translateY(0) scale(0.6);
        }
        15% {
            opacity: 1;
            transform: translateY(-40px) scale(1.3);
        }
        75% {
            opacity: 0.95;
            transform: translateY(-280px) scale(1.05);
        }
        100% {
            opacity: 0;
            transform: translateY(-420px) scale(0.8);
        }
    }

    /* Center Play/Pause Ripple Feedback */
    .center-feedback-icon {
        position: absolute;
        top: 50%;
        left: 50%;
        transform: translate(-50%, -50%) scale(0.5);
        width: 72px;
        height: 72px;
        background: rgba(0, 0, 0, 0.72);
        border-radius: 50%;
        display: flex;
        align-items: center;
        justify-content: center;
        color: #FFFFFF;
        font-size: 30px;
        pointer-events: none;
        z-index: 28;
        opacity: 0;
        transition: all 0.35s cubic-bezier(0.34, 1.56, 0.64, 1);
        backdrop-filter: blur(8px);
        -webkit-backdrop-filter: blur(8px);
        border: 1px solid rgba(255, 255, 255, 0.25);
        box-shadow: 0 10px 30px rgba(0, 0, 0, 0.6);
    }

    .center-feedback-icon.show-feedback {
        transform: translate(-50%, -50%) scale(1.1);
        opacity: 1;
    }

    /* Custom App-Like Controls Overlay */
    .video-controls-overlay {
        position: absolute; 
        inset: 0; 
        z-index: 30; 
        pointer-events: none;
        display: flex; 
        flex-direction: column; 
        justify-content: space-between; 
        padding: 20px 24px;
        opacity: 0; 
        transition: opacity 0.35s ease-in-out;
        background: linear-gradient(to bottom, rgba(0,0,0,0.72) 0%, transparent 24%, transparent 76%, rgba(0,0,0,0.88) 100%);
        box-sizing: border-box;
    }
    
    .video-controls-overlay.show-controls { 
        opacity: 1; 
    }

    .overlay-top-bar { 
        display: flex; 
        justify-content: space-between; 
        align-items: center; 
        gap: 16px;
    }

    .overlay-top-left { 
        display: flex;
        align-items: center;
        gap: 12px;
        max-width: 70%;
    }

    .overlay-title {
        color: #FFFFFF;
        font-size: 15px;
        font-weight: 700;
        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
        white-space: nowrap;
        overflow: hidden;
        text-overflow: ellipsis;
        text-shadow: 0 2px 4px rgba(0,0,0,0.6);
    }

    .overlay-bottom-bar { 
        display: flex; 
        justify-content: space-between; 
        align-items: center; 
        gap: 8px;
        width: 100%;
        box-sizing: border-box;
        overflow: visible;
        flex-wrap: nowrap;
    }

    .overlay-bottom-left {
        display: flex;
        align-items: center;
        gap: 6px;
        flex-shrink: 0;
    }

    .overlay-bottom-right {
        display: flex;
        align-items: center;
        gap: 6px;
        flex-shrink: 0;
    }

    .btn-fullscreen-toggle {
        flex-shrink: 0 !important;
    }

    /* Quick Emoji Reaction Strip */
    .quick-reaction-bar {
        pointer-events: auto;
        display: flex;
        align-items: center;
        gap: 6px;
        background: rgba(15, 23, 42, 0.80);
        padding: 6px 12px;
        border-radius: 24px;
        backdrop-filter: blur(12px);
        -webkit-backdrop-filter: blur(12px);
        border: 1px solid rgba(255, 255, 255, 0.18);
        box-shadow: 0 4px 16px rgba(0, 0, 0, 0.35);
        flex-shrink: 1;
        overflow: hidden;
    }

    .quick-emoji-btn {
        background: transparent;
        border: none;
        cursor: pointer;
        font-size: 20px;
        padding: 3px 6px;
        border-radius: 8px;
        transition: transform 0.15s cubic-bezier(0.34, 1.56, 0.64, 1);
        user-select: none;
        outline: none;
        display: flex;
        align-items: center;
        justify-content: center;
    }

    .quick-emoji-btn:hover {
        transform: scale(1.35) translateY(-3px);
        background: rgba(255, 255, 255, 0.15);
    }

    .quick-emoji-btn:active {
        transform: scale(1.0);
    }

    .overlay-btn {
        pointer-events: auto; 
        background: rgba(15, 23, 42, 0.75); 
        color: #FFFFFF;
        padding: 10px 16px; 
        border-radius: 12px; 
        font-size: 13.5px; 
        font-weight: 700;
        font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
        backdrop-filter: blur(12px); 
        -webkit-backdrop-filter: blur(12px);
        border: 1px solid rgba(255,255,255,0.2); 
        transition: all 0.15s cubic-bezier(0.4, 0, 0.2, 1);
        display: flex; 
        align-items: center; 
        gap: 8px; 
        box-shadow: 0 4px 15px rgba(0,0,0,0.3);
        cursor: pointer;
        outline: none;
        user-select: none;
        white-space: nowrap;
        flex-shrink: 0;
    }

    .overlay-btn:hover { 
        background: rgba(79, 70, 229, 0.95); 
        transform: translateY(-2px); 
        border-color: rgba(255,255,255,0.45); 
        box-shadow: 0 6px 20px rgba(79, 70, 229, 0.4);
    }

    .overlay-btn:active { 
        transform: translateY(0); 
    }

    .overlay-btn.btn-sync { 
        background: rgba(239, 68, 68, 0.88); 
        margin-left: auto;
    }

    .overlay-btn.btn-sync:hover { 
        background: rgba(239, 68, 68, 1); 
        box-shadow: 0 6px 20px rgba(239, 68, 68, 0.45);
    }

    /* Container Queries for responsive player resizing (e.g. when side panel opens) */
    @container player (max-width: 860px) {
        .overlay-btn {
            padding: 8px 10px;
            font-size: 12px;
            gap: 4px;
        }
        .overlay-btn .btn-label {
            display: none !important;
        }
        .quick-reaction-bar {
            padding: 4px 8px;
            gap: 2px;
        }
        .quick-emoji-btn {
            font-size: 17px;
            padding: 2px 3px;
        }
    }

    @container player (max-width: 580px) {
        .video-controls-overlay {
            padding: 12px 14px;
        }
        .quick-reaction-bar {
            display: none !important;
        }
        .overlay-btn {
            padding: 6px 8px;
            font-size: 11px;
        }
        .overlay-top-left {
            max-width: 60%;
        }
    }

    @media (max-width: 860px) {
        .overlay-btn .btn-label {
            display: none !important;
        }
        .overlay-btn {
            padding: 8px 10px;
        }
    }

    @media (max-width: 580px) {
        .quick-reaction-bar {
            display: none !important;
        }
        .overlay-title {
            max-width: 130px;
            font-size: 12px;
        }
    }
''';

void _ensurePlayerStylesInjected() {
  if (html.document.getElementById('ssc-cinematic-player-styles') != null) return;
  final style = html.StyleElement()
    ..id = 'ssc-cinematic-player-styles'
    ..text = _kPlayerCss;
  html.document.head?.append(style);
}

Widget buildWebYouTubePlayer({
  Key? key,
  required String videoId,
  required bool isLive,
  required bool autoPlay,
  String? title,
}) {
  final viewType = 'youtube-web-player-$videoId';
  _ensurePlayerStylesInjected();

  if (!_registeredViewTypes.contains(viewType)) {
    _registeredViewTypes.add(viewType);
    ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
      final wrapper = html.DivElement()..className = 'cinematic-player-wrapper';
      wrapper.style
        ..position = 'relative'
        ..width = '100%'
        ..height = '100%'
        ..backgroundColor = '#000000'
        ..overflow = 'hidden'
        ..display = 'flex'
        ..alignItems = 'center'
        ..justifyContent = 'center'
        ..userSelect = 'none';

      // Scoped stylesheet appended directly into wrapper (penetrates Flutter Web Shadow DOM)
      final scopedStyle = html.StyleElement()..text = _kPlayerCss;
      wrapper.append(scopedStyle);

      // Prevent right-click context menu so YouTube video links / context menu never appear
      wrapper.onContextMenu.listen((e) => e.preventDefault());

      final hostOrigin = html.window.location.origin;

      // 🛡️ ANTI-SUBLINKS CLEAN EMBED URL:
      // • iv_load_policy=3: Disables video annotations and interactive info-card links
      // • disablekb=1: Disables iframe keyboard shortcuts so links cannot be focused
      // • fs=0: Hides native fullscreen button (our custom app button handles it)
      // • rel=0: Restricts recommendations to current channel only (no external sublinks)
      // • playsinline=1: Ensures inline video playback across mobile & desktop
      final cleanSrc =
          'https://www.youtube-nocookie.com/embed/$videoId?autoplay=${autoPlay ? 1 : 0}&controls=0&rel=0&iv_load_policy=3&disablekb=1&fs=0&playsinline=1&enablejsapi=1&origin=$hostOrigin&widget_referrer=$hostOrigin';

      final iframe = html.IFrameElement()
        ..className = 'youtube-iframe'
        ..src = cleanSrc
        // 🛡️ BROWSER SANDBOX: strictly forbids popups and external navigation links!
        ..setAttribute('sandbox', 'allow-scripts allow-same-origin allow-presentation')
        ..allow = 'autoplay; encrypted-media; fullscreen; picture-in-picture'
        ..allowFullscreen = true;

      // Bulletproof direct inline styles
      iframe.style
        ..position = 'absolute'
        ..top = '0'
        ..left = '0'
        ..width = '100%'
        ..height = '100%'
        ..border = 'none'
        ..display = 'block'
        ..pointerEvents = 'none';

      // 🛡️ THE MAGIC INTERCEPTOR: Covers the iframe 100% of the time!
      final interceptor = html.DivElement()..className = 'touch-interceptor';
      interceptor.style
        ..position = 'absolute'
        ..top = '0'
        ..left = '0'
        ..width = '100%'
        ..height = '100%'
        ..zIndex = '20'
        ..backgroundColor = 'transparent'
        ..cursor = 'default'
        ..pointerEvents = 'auto';

      interceptor.onContextMenu.listen((e) => e.preventDefault());
      interceptor.onDragStart.listen((e) => e.preventDefault());

      // 🎈 FLOATING EMOJI REACTIONS LAYER
      final reactionsContainer = html.DivElement()..className = 'web-floating-reactions';

      // ⚡ CENTER FEEDBACK RIPPLE (for Click Play/Pause)
      final centerFeedback = html.DivElement()..className = 'center-feedback-icon';

      // 🎛️ CUSTOM CONTROLS OVERLAY
      final overlay = html.DivElement()..className = 'video-controls-overlay';

      // --- TOP BAR ---
      final topBar = html.DivElement()..className = 'overlay-top-bar';
      final topLeft = html.DivElement()..className = 'overlay-top-left';
      final btnBack = html.ButtonElement()
        ..className = 'overlay-btn btn-back'
        ..setInnerHtml('<span>⬅</span> <span class="btn-label">Back</span>');
      topLeft.append(btnBack);

      if (title != null && title.trim().isNotEmpty) {
        final titleSpan = html.SpanElement()
          ..className = 'overlay-title'
          ..text = title;
        topLeft.append(titleSpan);
      }
      topBar.append(topLeft);

      final btnSync = html.ButtonElement()
        ..className = 'overlay-btn btn-sync'
        ..setInnerHtml('🔴 <span class="btn-label">SYNC LIVE</span>');
      if (isLive) {
        topBar.append(btnSync);
      }

      // --- BOTTOM BAR ---
      final bottomBar = html.DivElement()..className = 'overlay-bottom-bar';

      // Bottom Left: Play/Pause & Mute
      final bottomLeft = html.DivElement()..className = 'overlay-bottom-left';
      final btnPlayPause = html.ButtonElement()
        ..className = 'overlay-btn btn-play-pause'
        ..title = 'Play / Pause'
        ..setInnerHtml('<span>⏸</span> <span class="btn-label">Pause</span>');
      final btnMute = html.ButtonElement()
        ..className = 'overlay-btn btn-mute'
        ..title = 'Mute / Unmute'
        ..setInnerHtml('<span>🔊</span> <span class="btn-label">Mute</span>');
      bottomLeft.append(btnPlayPause);
      bottomLeft.append(btnMute);

      // Bottom Center: Quick Emoji Reaction Bar (Visible directly on player!)
      final quickReactionBar = html.DivElement()..className = 'quick-reaction-bar';
      const emojis = ['❤️', '🔥', '👏', '💡', '🚀', '🙋‍♂️'];

      // Bottom Right: Fullscreen, Chat, Doubts
      final bottomRight = html.DivElement()..className = 'overlay-bottom-right';
      final btnFS = html.ButtonElement()
        ..className = 'overlay-btn btn-fullscreen-toggle'
        ..title = 'Toggle Fullscreen'
        ..setInnerHtml('<span>⛶</span> <span class="btn-label">Fullscreen</span>');
      final btnChat = html.ButtonElement()
        ..className = 'overlay-btn btn-chat'
        ..title = 'Live Class Chat'
        ..setInnerHtml('<span>💬</span> <span class="btn-label">Live Chat</span>');
      final btnDoubts = html.ButtonElement()
        ..className = 'overlay-btn btn-doubts'
        ..title = 'AI Doubts Solver'
        ..setInnerHtml('<span>✨</span> <span class="btn-label">Doubts</span>');

      bottomRight.append(btnFS);
      bottomRight.append(btnChat);
      bottomRight.append(btnDoubts);

      bottomBar.append(bottomLeft);
      bottomBar.append(quickReactionBar);
      bottomBar.append(bottomRight);

      overlay.append(topBar);
      overlay.append(bottomBar);

      // --- FLOATING EMOJI SPAWN LOGIC (Right Side of Screen) ---
      final random = math.Random();
      void spawnFloatingEmoji(String emoji, [String? sender]) {
        final el = html.DivElement()
          ..className = 'floating-emoji-item'
          ..text = emoji;

        // Float exclusively on the RIGHT side of the video stage (20px to 75px from right edge)
        final rightPx = 20 + random.nextInt(55);
        el.style.right = '${rightPx}px';

        reactionsContainer.append(el);
        Timer(const Duration(milliseconds: 2600), () {
          el.remove();
        });
      }

      // Quick Emoji Buttons Click Handlers
      for (final emoji in emojis) {
        final btn = html.ButtonElement()
          ..className = 'quick-emoji-btn'
          ..text = emoji;
        btn.onClick.listen((e) {
          e.stopPropagation();
          spawnFloatingEmoji(emoji, 'You');
          try {
            final now = DateTime.now().millisecondsSinceEpoch;
            final pulseId = '${now}_Student_${random.nextInt(99999)}';
            FirebaseFirestore.instance
                .collection('live_session')
                .doc('current')
                .collection('realtime_feed')
                .doc('reaction')
                .set({
              'emoji': emoji,
              'sender': 'Student',
              'timestamp': now,
              'pulseId': pulseId,
            }, SetOptions(merge: true));

            FirebaseFirestore.instance
                .collection('live_session')
                .doc('current')
                .collection('reactions')
                .add({
              'emoji': emoji,
              'sender': 'Student',
              'timestamp': now,
            });
          } catch (_) {}

          WebFullscreenHelper.dispatchSpawnEmoji(emoji);
        });
        quickReactionBar.append(btn);
      }

      // Listen to Remote Emoji Reactions from Firestore
      String? lastHandledPulseId;
      FirebaseFirestore.instance
          .collection('live_session')
          .doc('current')
          .collection('realtime_feed')
          .doc('reaction')
          .snapshots()
          .listen((docSnap) {
        if (!docSnap.exists) return;
        final data = docSnap.data();
        if (data == null) return;
        final pulseId = data['pulseId']?.toString();
        if (pulseId != null && pulseId != lastHandledPulseId) {
          lastHandledPulseId = pulseId;
          final emoji = data['emoji']?.toString() ?? '❤️';
          spawnFloatingEmoji(emoji, data['sender']?.toString());
        }
      });

      // Listen to local emojis dispatched by Chat Panel
      WebFullscreenHelper.listenSpawnEmoji((emoji) {
        spawnFloatingEmoji(emoji);
      });

      // --- YOUTUBE COMMANDS & PLAYBACK CONTROL VIA POSTMESSAGE ---
      void sendVideoCommand(String command, [List<dynamic>? args]) {
        try {
          final cw = iframe.contentWindow;
          if (cw != null) {
            cw.postMessage('{"event":"listening"}', '*');
            String argsJson = '[]';
            if (args != null && args.isNotEmpty) {
              final formattedArgs = args.map((a) {
                if (a is String) return '"$a"';
                if (a is num || a is bool) return '$a';
                return '"$a"';
              }).join(',');
              argsJson = '[$formattedArgs]';
            }
            cw.postMessage('{"event":"command","func":"$command","args":$argsJson}', '*');
          }
        } catch (_) {}

        try {
          WebFullscreenHelper.sendVideoCommand(command, args);
        } catch (_) {}
      }

      iframe.onLoad.listen((_) {
        try {
          iframe.contentWindow?.postMessage('{"event":"listening"}', '*');
          if (autoPlay) {
            sendVideoCommand('playVideo');
          }
        } catch (_) {}
      });

      bool isPlaying = true;
      bool isMuted = false;

      void showCenterFeedback(String icon) {
        centerFeedback.text = icon;
        centerFeedback.classes.add('show-feedback');
        Timer(const Duration(milliseconds: 500), () {
          centerFeedback.classes.remove('show-feedback');
        });
      }

      void togglePlay() {
        isPlaying = !isPlaying;
        if (isPlaying) {
          sendVideoCommand('playVideo');
          btnPlayPause.setInnerHtml('<span>⏸</span> <span class="btn-label">Pause</span>');
          showCenterFeedback('▶');
        } else {
          sendVideoCommand('pauseVideo');
          btnPlayPause.setInnerHtml('<span>▶</span> <span class="btn-label">Play</span>');
          showCenterFeedback('⏸');
        }
      }

      void toggleMute() {
        isMuted = !isMuted;
        if (isMuted) {
          sendVideoCommand('mute');
          btnMute.setInnerHtml('<span>🔇</span> <span class="btn-label">Unmute</span>');
        } else {
          sendVideoCommand('unMute');
          sendVideoCommand('setVolume', [100]);
          btnMute.setInnerHtml('<span>🔊</span> <span class="btn-label">Mute</span>');
        }
      }

      // --- AUTO-HIDE & ADVANCED EDGE DETECTION CONTROLS ---
      Timer? hideTimer;
      void hideControls() {
        overlay.classes.remove('show-controls');
        interceptor.style.cursor = 'none'; // Hides cursor in theater mode
      }

      void showControls(html.Event e) {
        // Edge detection: Instant hide if mouse is placed on corners/edges
        if (e is html.MouseEvent) {
          const threshold = 35;
          final rect = wrapper.getBoundingClientRect();
          final x = e.client.x - rect.left;
          final y = e.client.y - rect.top;
          if (x <= threshold || x >= rect.width - threshold || y <= threshold || y >= rect.height - threshold) {
            hideControls();
            hideTimer?.cancel();
            return;
          }
        }

        overlay.classes.add('show-controls');
        interceptor.style.cursor = 'default'; // Standard clean arrow pointer over video stage

        hideTimer?.cancel();
        hideTimer = Timer(const Duration(milliseconds: 3500), hideControls);
      }

      interceptor.onMouseMove.listen(showControls);
      interceptor.onTouchStart.listen(showControls);

      // 🛡️ CRITICAL FIX: Clicking video stage ONLY reveals/toggles controls.
      // It NEVER stops or pauses a running live lecture!
      interceptor.onClick.listen((e) {
        e.preventDefault();
        e.stopPropagation();
        if (overlay.classes.contains('show-controls')) {
          hideControls();
          hideTimer?.cancel();
        } else {
          showControls(e);
        }
      });

      wrapper.onMouseLeave.listen((_) {
        hideControls();
        hideTimer?.cancel();
      });

      btnPlayPause.onClick.listen((e) {
        e.stopPropagation();
        togglePlay();
      });

      btnMute.onClick.listen((e) {
        e.stopPropagation();
        toggleMute();
      });

      // 🛡️ LIVE CLASS AUTO-RESUMPTION WATCHDOG & STATE SYNC:
      // Listens to YouTube Iframe events. If the live stream pauses due to buffer underrun
      // or momentary network dip, this immediately re-triggers playVideo() so class never stops!
      html.window.onMessage.listen((event) {
        try {
          if (event.data is String) {
            final data = event.data as String;
            if (data.contains('"event":"onStateChange"')) {
              // 1 = PLAYING, 2 = PAUSED, 3 = BUFFERING, 0 = ENDED
              if (data.contains('"info":1')) {
                isPlaying = true;
                btnPlayPause.setInnerHtml('<span>⏸</span> <span class="btn-label">Pause</span>');
              } else if (data.contains('"info":2')) {
                if (isLive && isPlaying) {
                  // Auto-recover from live buffer dip without freezing
                  sendVideoCommand('playVideo');
                } else if (!isLive) {
                  btnPlayPause.setInnerHtml('<span>▶</span> <span class="btn-label">Play</span>');
                }
              }
            }
          }
        } catch (_) {}
      });

      // Periodic live heartbeat watchdog
      if (isLive) {
        Timer.periodic(const Duration(seconds: 4), (timer) {
          if (wrapper.isConnected != true) {
            timer.cancel();
            return;
          }
          if (isPlaying) {
            sendVideoCommand('playVideo');
          }
        });
      }

      // Universal Screen WakeLock: prevents PC and mobile from sleeping during class
      try {
        final nav = html.window.navigator;
        // ignore: avoid_dynamic_calls
        (nav as dynamic).wakeLock?.request('screen');
      } catch (_) {}

      void updateFsButton() {
        final isFs = html.document.fullscreenElement != null;
        if (isFs) {
          btnFS.setInnerHtml('<span>🗗</span> <span class="btn-label">Exit Fullscreen</span>');
          btnFS.title = 'Exit Fullscreen (Esc)';
          btnBack.setInnerHtml('<span>🗗</span> <span class="btn-label">Exit Fullscreen</span>');
        } else {
          btnFS.setInnerHtml('<span>⛶</span> <span class="btn-label">Fullscreen</span>');
          btnFS.title = 'Fullscreen (F)';
          btnBack.setInnerHtml('<span>⬅</span> <span class="btn-label">Back</span>');
        }
      }

      // Initial state synchronization
      updateFsButton();

      btnBack.onClick.listen((e) {
        e.stopPropagation();
        if (html.document.fullscreenElement != null) {
          try {
            html.document.exitFullscreen();
          } catch (_) {}
          Timer(const Duration(milliseconds: 60), updateFsButton);
          return;
        }
        html.window.dispatchEvent(html.CustomEvent('app-player-back'));
      });

      if (isLive) {
        btnSync.onClick.listen((e) {
          e.stopPropagation();
          iframe.src = iframe.src;
          sendVideoCommand('seekTo', [999999, true]);
          sendVideoCommand('playVideo');
          html.window.dispatchEvent(html.CustomEvent('app-player-sync'));
        });
      }

      btnFS.onClick.listen((e) {
        e.stopPropagation();
        try {
          if (html.document.fullscreenElement != null) {
            html.document.exitFullscreen();
          } else {
            html.document.documentElement?.requestFullscreen();
          }
        } catch (_) {}
        Timer(const Duration(milliseconds: 60), updateFsButton);
        Timer(const Duration(milliseconds: 250), updateFsButton);
        html.window.dispatchEvent(html.CustomEvent('app-player-fullscreen'));
      });

      html.document.onFullscreenChange.listen((_) {
        updateFsButton();
        Timer(const Duration(milliseconds: 100), updateFsButton);
      });

      html.window.onResize.listen((_) {
        updateFsButton();
      });

      btnChat.onClick.listen((e) {
        e.stopPropagation();
        html.window.dispatchEvent(html.CustomEvent('app-player-chat'));
      });

      btnDoubts.onClick.listen((e) {
        e.stopPropagation();
        html.window.dispatchEvent(html.CustomEvent('app-player-doubts'));
      });

      // Construct the DOM tree
      wrapper.append(iframe);
      wrapper.append(interceptor);
      wrapper.append(reactionsContainer);
      wrapper.append(centerFeedback);
      wrapper.append(overlay);
      return wrapper;
    });
  }

  return HtmlElementView(
    key: key ?? ValueKey(viewType),
    viewType: viewType,
  );
}
