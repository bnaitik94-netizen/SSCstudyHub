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

    /* Center Play/Pause & Volume Ripple Feedback */
    .center-feedback-icon {
        position: absolute;
        top: 50%;
        left: 50%;
        transform: translate(-50%, -50%) scale(0.5);
        min-width: 76px;
        height: 76px;
        padding: 0 18px;
        box-sizing: border-box;
        white-space: nowrap;
        background: rgba(15, 23, 42, 0.88);
        border-radius: 38px;
        display: flex;
        align-items: center;
        justify-content: center;
        color: #FFFFFF;
        font-size: 26px;
        font-weight: 800;
        pointer-events: none;
        z-index: 28;
        opacity: 0;
        transition: all 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
        backdrop-filter: blur(12px);
        -webkit-backdrop-filter: blur(12px);
        border: 1.5px solid rgba(255, 255, 255, 0.35);
        box-shadow: 0 10px 30px rgba(0, 0, 0, 0.75);
    }

    .center-feedback-icon.show-feedback {
        transform: translate(-50%, -50%) scale(1.1);
        opacity: 1;
    }

    /* Live Beacon Indicator */
    .live-badge-beacon {
        display: inline-flex;
        align-items: center;
        gap: 6px;
        background: rgba(239, 68, 68, 0.22);
        border: 1px solid rgba(239, 68, 68, 0.6);
        padding: 4px 10px;
        border-radius: 20px;
        color: #FFFFFF;
        font-size: 11px;
        font-weight: 800;
        letter-spacing: 0.8px;
        backdrop-filter: blur(8px);
        -webkit-backdrop-filter: blur(8px);
        user-select: none;
        flex-shrink: 0;
    }

    .live-beacon-dot {
        width: 8px;
        height: 8px;
        border-radius: 50%;
        background: #EF4444;
        box-shadow: 0 0 8px #EF4444;
        animation: liveBeaconPulse 1.4s infinite ease-in-out;
    }

    @keyframes liveBeaconPulse {
        0%, 100% { opacity: 1; transform: scale(1); }
        50% { opacity: 0.35; transform: scale(0.8); }
    }

    /* 🔊 Granular Volume Slider Container */
    .volume-control-group {
        display: flex;
        align-items: center;
        position: relative;
        pointer-events: auto;
    }

    .volume-slider-wrapper {
        width: 0px;
        opacity: 0;
        overflow: hidden;
        transition: width 0.22s cubic-bezier(0.4, 0, 0.2, 1), opacity 0.2s ease, padding 0.2s ease;
        display: flex;
        align-items: center;
        padding: 0;
    }

    .volume-control-group:hover .volume-slider-wrapper,
    .volume-control-group.active .volume-slider-wrapper {
        width: 84px;
        opacity: 1;
        padding: 0 8px 0 4px;
    }

    .volume-slider {
        -webkit-appearance: none;
        appearance: none;
        width: 100%;
        height: 5px;
        border-radius: 4px;
        background: rgba(255, 255, 255, 0.35);
        outline: none;
        cursor: pointer;
        transition: background 0.15s ease;
    }

    .volume-slider::-webkit-slider-thumb {
        -webkit-appearance: none;
        appearance: none;
        width: 14px;
        height: 14px;
        border-radius: 50%;
        background: #38BDF8;
        cursor: pointer;
        box-shadow: 0 1px 5px rgba(0, 0, 0, 0.6);
        transition: transform 0.12s ease;
    }

    .volume-slider::-webkit-slider-thumb:hover {
        transform: scale(1.25);
        background: #FFFFFF;
    }

    .shortcut-badge {
        font-size: 10px;
        opacity: 0.6;
        background: rgba(255, 255, 255, 0.16);
        padding: 1px 5px;
        border-radius: 4px;
        margin-left: 3px;
        font-family: monospace;
        font-weight: 700;
        letter-spacing: 0.4px;
    }

    /* ⚡ IN-HOUSE ZERO-PERMISSION 200% SUPER BOOSTER (PC & MOBILE) */
    .btn-volume-max {
        background: linear-gradient(135deg, rgba(16, 185, 129, 0.9), rgba(5, 150, 105, 0.95)) !important;
        border: 1px solid rgba(52, 211, 153, 0.6) !important;
        box-shadow: 0 4px 14px rgba(16, 185, 129, 0.35) !important;
        color: #FFFFFF !important;
        padding: 7px 12px !important;
        font-size: 12px !important;
        font-weight: 800 !important;
        letter-spacing: 0.3px !important;
        border-radius: 12px !important;
        display: inline-flex !important;
        align-items: center !important;
        gap: 5px !important;
        cursor: pointer !important;
        transition: all 0.2s cubic-bezier(0.34, 1.56, 0.64, 1) !important;
        white-space: nowrap !important;
        flex-shrink: 0 !important;
        pointer-events: auto !important;
        outline: none !important;
    }

    .btn-volume-max:hover {
        transform: translateY(-2px) scale(1.04) !important;
        box-shadow: 0 6px 20px rgba(16, 185, 129, 0.55) !important;
        border-color: #A7F3D0 !important;
    }

    .btn-volume-max:active {
        transform: translateY(0) scale(0.98) !important;
    }

    .btn-volume-max.boost-on {
        background: linear-gradient(135deg, #F59E0B, #EF4444) !important;
        border-color: #FDE047 !important;
        box-shadow: 0 4px 18px rgba(245, 158, 11, 0.6) !important;
        animation: superPulse 2s infinite ease-in-out !important;
    }

    @keyframes superPulse {
        0%, 100% { box-shadow: 0 0 10px rgba(245, 158, 11, 0.6); transform: scale(1); }
        50% { box-shadow: 0 0 20px rgba(239, 68, 68, 0.85); transform: scale(1.03); }
    }

    @container player (max-width: 768px) {
        .video-controls-overlay {
            padding: 12px 14px max(14px, env(safe-area-inset-bottom, 14px)) 14px !important;
        }

        .touch-interceptor {
            touch-action: manipulation;
            -webkit-tap-highlight-color: transparent;
        }

        .overlay-btn {
            min-height: 38px !important;
            padding: 7px 11px !important;
            font-size: 13px !important;
            border-radius: 10px !important;
            touch-action: manipulation !important;
            -webkit-tap-highlight-color: transparent !important;
        }

        .overlay-btn .btn-label {
            display: none !important;
        }

        .btn-volume-max {
            min-height: 38px !important;
            padding: 7px 11px !important;
            font-size: 12px !important;
            border-radius: 10px !important;
            touch-action: manipulation !important;
            -webkit-tap-highlight-color: transparent !important;
        }

        .btn-volume-max .vm-badge-text {
            font-size: 11px !important;
            font-weight: 800 !important;
        }

        /* Hide desktop physical shortcut badges on mobile */
        .shortcut-badge {
            display: none !important;
        }

        /* In mobile portrait, Live Chat and Doubts are directly below video */
        .overlay-bottom-right .btn-chat,
        .overlay-bottom-right .btn-doubts {
            display: none !important;
        }

        .quick-reaction-bar {
            display: none !important;
        }
        .overlay-top-left {
            max-width: 75% !important;
        }

        /* Touch-friendly volume slider on mobile */
        .volume-control-group.active .volume-slider-wrapper {
            width: 95px !important;
            padding: 0 8px 0 4px !important;
        }
        .volume-slider {
            height: 7px !important;
            border-radius: 6px !important;
            touch-action: manipulation !important;
        }
        .volume-slider::-webkit-slider-thumb {
            width: 20px !important;
            height: 20px !important;
            box-shadow: 0 2px 6px rgba(0, 0, 0, 0.7) !important;
        }
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

    /* Prevent accidental taps on hidden buttons when overlay is faded out on mobile */
    .video-controls-overlay:not(.show-controls) * {
        pointer-events: none !important;
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
            padding: 10px 12px max(12px, env(safe-area-inset-bottom, 12px)) 12px !important;
        }
        .quick-reaction-bar {
            display: none !important;
        }
        .overlay-btn {
            min-height: 36px !important;
            padding: 6px 9px !important;
            font-size: 12px !important;
            gap: 4px !important;
        }
        .btn-volume-max {
            min-height: 36px !important;
            padding: 6px 9px !important;
            font-size: 11.5px !important;
        }
        .overlay-top-left {
            max-width: 65% !important;
        }
    }

    @container player (max-width: 440px) {
        .video-controls-overlay {
            padding: 8px 10px max(10px, env(safe-area-inset-bottom, 10px)) 10px !important;
        }
        .overlay-btn {
            min-height: 35px !important;
            padding: 5px 8px !important;
            font-size: 11.5px !important;
        }
        .btn-volume-max {
            min-height: 35px !important;
            padding: 5px 8px !important;
            font-size: 11px !important;
        }
        .overlay-title {
            max-width: 125px !important;
            font-size: 11.5px !important;
        }
        .center-feedback-icon {
            min-width: 64px !important;
            height: 64px !important;
            font-size: 20px !important;
            padding: 0 12px !important;
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

    @media (max-height: 500px) and (orientation: landscape) {
        .video-controls-overlay {
            padding: 8px 16px max(10px, env(safe-area-inset-bottom, 10px)) 16px !important;
        }
        .overlay-btn {
            min-height: 34px !important;
            padding: 5px 10px !important;
            font-size: 12px !important;
        }
        .btn-volume-max {
            min-height: 34px !important;
            padding: 5px 10px !important;
            font-size: 11.5px !important;
        }
        .center-feedback-icon {
            min-width: 60px !important;
            height: 60px !important;
            font-size: 20px !important;
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
        ..title = 'Back to Dashboard (Esc)'
        ..setInnerHtml('<span>⬅</span> <span class="btn-label">Back</span>');
      topLeft.append(btnBack);

      if (isLive) {
        final liveBeacon = html.DivElement()
          ..className = 'live-badge-beacon'
          ..setInnerHtml('<span class="live-beacon-dot"></span> <span>LIVE</span>');
        topLeft.append(liveBeacon);
      }

      if (title != null && title.trim().isNotEmpty) {
        final titleSpan = html.SpanElement()
          ..className = 'overlay-title'
          ..title = title
          ..text = title;
        topLeft.append(titleSpan);
      }
      topBar.append(topLeft);

      final btnSync = html.ButtonElement()
        ..className = 'overlay-btn btn-sync'
        ..title = 'Jump to Realtime Live Broadcast'
        ..setInnerHtml('🔴 <span class="btn-label">SYNC LIVE</span>');
      if (isLive) {
        topBar.append(btnSync);
      }

      // --- BOTTOM BAR ---
      final bottomBar = html.DivElement()..className = 'overlay-bottom-bar';

      // Bottom Left: Play/Pause & Granular Volume Control
      final bottomLeft = html.DivElement()..className = 'overlay-bottom-left';
      final btnPlayPause = html.ButtonElement()
        ..className = 'overlay-btn btn-play-pause'
        ..title = 'Play / Pause (Space / K)'
        ..setInnerHtml('<span>⏸</span> <span class="btn-label">Pause</span> <span class="shortcut-badge">K</span>');

      final volumeGroup = html.DivElement()..className = 'volume-control-group';
      final btnMute = html.ButtonElement()
        ..className = 'overlay-btn btn-mute'
        ..title = 'Mute / Unmute (M) • Scroll to adjust'
        ..setInnerHtml('<span>🔊</span> <span class="btn-label">Mute</span> <span class="shortcut-badge">M</span>');
      
      final volumeWrapper = html.DivElement()..className = 'volume-slider-wrapper';
      final volumeSlider = html.InputElement(type: 'range')
        ..className = 'volume-slider'
        ..min = '0'
        ..max = '200'
        ..value = '100'
        ..title = 'Volume Slider (0% - 200%)';
      volumeWrapper.append(volumeSlider);
      volumeGroup.append(btnMute);
      volumeGroup.append(volumeWrapper);

      bottomLeft.append(btnPlayPause);
      bottomLeft.append(volumeGroup);

      // ⚡ In-House Zero-Permission 200% Super Volume Booster Button
      final btnMaxVolume = html.ButtonElement()
        ..className = 'btn-volume-max'
        ..title = 'Super Volume Booster (0% - 200%)'
        ..setInnerHtml('<span>⚡</span> <span class="vm-badge-text">200% Boost</span>');
      bottomLeft.append(btnMaxVolume);

      // Bottom Center: Quick Emoji Reaction Bar (Visible directly on player!)
      final quickReactionBar = html.DivElement()..className = 'quick-reaction-bar';
      const emojis = ['❤️', '🔥', '👏', '💡', '🚀', '🙋‍♂️'];

      // Bottom Right: Fullscreen, Chat, Doubts
      final bottomRight = html.DivElement()..className = 'overlay-bottom-right';
      final btnFS = html.ButtonElement()
        ..className = 'overlay-btn btn-fullscreen-toggle'
        ..title = 'Toggle Fullscreen (F) • Double-click video'
        ..setInnerHtml('<span>⛶</span> <span class="btn-label">Fullscreen</span> <span class="shortcut-badge">F</span>');
      final btnChat = html.ButtonElement()
        ..className = 'overlay-btn btn-chat'
        ..title = 'Live Class Chat (C)'
        ..setInnerHtml('<span>💬</span> <span class="btn-label">Live Chat</span> <span class="shortcut-badge">C</span>');
      final btnDoubts = html.ButtonElement()
        ..className = 'overlay-btn btn-doubts'
        ..title = 'AI Doubts Solver (D)'
        ..setInnerHtml('<span>✨</span> <span class="btn-label">Doubts</span> <span class="shortcut-badge">D</span>');

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

      int currentVolume = 100;
      try {
        final saved = html.window.localStorage['ssc_player_volume'];
        if (saved != null) {
          final parsed = int.tryParse(saved);
          if (parsed != null && parsed >= 0 && parsed <= 200) {
            currentVolume = parsed;
          }
        }
      } catch (_) {}
      volumeSlider.value = currentVolume.toString();

      iframe.onLoad.listen((_) {
        try {
          iframe.contentWindow?.postMessage('{"event":"listening"}', '*');
          if (autoPlay) {
            sendVideoCommand('playVideo');
          }
          final ytVol = currentVolume.clamp(0, 100);
          sendVideoCommand('setVolume', [ytVol]);
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

      void updateVolumeDisplay() {
        if (isMuted || currentVolume == 0) {
          btnMute.setInnerHtml('<span>🔇</span> <span class="btn-label">Unmute</span> <span class="shortcut-badge">M</span>');
        } else if (currentVolume < 50) {
          btnMute.setInnerHtml('<span>🔉</span> <span class="btn-label">Mute</span> <span class="shortcut-badge">M</span>');
        } else if (currentVolume <= 100) {
          btnMute.setInnerHtml('<span>🔊</span> <span class="btn-label">Mute</span> <span class="shortcut-badge">M</span>');
        } else {
          btnMute.setInnerHtml('<span>⚡</span> <span class="btn-label">Boost</span> <span class="shortcut-badge">M</span>');
        }

        if (currentVolume > 100) {
          btnMaxVolume.classes.add('boost-on');
          btnMaxVolume.setInnerHtml('<span>⚡</span> <span class="vm-badge-text">$currentVolume% Boost</span>');
        } else {
          btnMaxVolume.classes.remove('boost-on');
          btnMaxVolume.setInnerHtml('<span>⚡</span> <span class="vm-badge-text">200% Boost</span>');
        }
      }

      void setVolume(int vol, [bool syncSlider = true]) {
        currentVolume = vol.clamp(0, 200);
        if (syncSlider) {
          volumeSlider.value = currentVolume.toString();
        }
        if (currentVolume == 0) {
          isMuted = true;
          sendVideoCommand('mute');
        } else {
          if (isMuted) {
            isMuted = false;
            sendVideoCommand('unMute');
          }
          final ytVol = currentVolume.clamp(0, 100);
          sendVideoCommand('setVolume', [ytVol]);
        }
        updateVolumeDisplay();
        try {
          html.window.localStorage['ssc_player_volume'] = currentVolume.toString();
        } catch (_) {}
      }

      int lastTogglePlayTime = 0;
      void togglePlay() {
        final now = DateTime.now().millisecondsSinceEpoch;
        if (now - lastTogglePlayTime < 180) return;
        lastTogglePlayTime = now;

        isPlaying = !isPlaying;
        if (isPlaying) {
          sendVideoCommand('playVideo');
          btnPlayPause.setInnerHtml('<span>⏸</span> <span class="btn-label">Pause</span> <span class="shortcut-badge">K</span>');
          showCenterFeedback('▶');
        } else {
          sendVideoCommand('pauseVideo');
          btnPlayPause.setInnerHtml('<span>▶</span> <span class="btn-label">Play</span> <span class="shortcut-badge">K</span>');
          showCenterFeedback('⏸');
        }
      }

      int lastToggleMuteTime = 0;
      void toggleMute() {
        final now = DateTime.now().millisecondsSinceEpoch;
        if (now - lastToggleMuteTime < 180) return;
        lastToggleMuteTime = now;

        isMuted = !isMuted;
        if (isMuted) {
          sendVideoCommand('mute');
          showCenterFeedback('🔇');
        } else {
          sendVideoCommand('unMute');
          if (currentVolume == 0) currentVolume = 50;
          volumeSlider.value = currentVolume.toString();
          final ytVol = currentVolume.clamp(0, 100);
          sendVideoCommand('setVolume', [ytVol]);
          showCenterFeedback(currentVolume < 50 ? '🔉' : '🔊');
        }
        updateVolumeDisplay();
      }

      volumeSlider.onInput.listen((_) {
        final val = int.tryParse(volumeSlider.value ?? '100') ?? 100;
        setVolume(val, false);
        if (val > 100) {
          showCenterFeedback('⚡ $val%');
        } else {
          showCenterFeedback(val == 0 ? '🔇' : (val < 50 ? '🔉' : '🔊 $val%'));
        }
      });

      volumeGroup.onWheel.listen((e) {
        e.preventDefault();
        e.stopPropagation();
        final delta = (e.deltaY < 0) ? 5 : -5;
        setVolume(currentVolume + delta);
        if (currentVolume > 100) {
          showCenterFeedback('⚡ $currentVolume%');
        } else {
          showCenterFeedback(currentVolume == 0 ? '🔇' : (currentVolume < 50 ? '🔉' : '🔊 $currentVolume%'));
        }
      });

      // ⚡ In-House 200% Super Volume Booster Toggle (Touch & Click)
      btnMaxVolume.onClick.listen((e) {
        e.stopPropagation();
        if (isMuted) toggleMute();
        if (currentVolume >= 200) {
          setVolume(100);
          showCenterFeedback('🔊 100%');
        } else {
          setVolume(200);
          showCenterFeedback('⚡ 200% BOOST');
        }
      });

      // --- SMOOTH AUTO-HIDE CONTROLS (WITHOUT BUGGY EDGE THRESHOLD) ---
      Timer? hideTimer;
      void hideControls() {
        overlay.classes.remove('show-controls');
        interceptor.style.cursor = 'none'; // Hides cursor in cinema/theater mode
      }

      int controlsShownAt = 0;
      void showControls([html.Event? e]) {
        overlay.classes.add('show-controls');
        interceptor.style.cursor = 'default';
        controlsShownAt = DateTime.now().millisecondsSinceEpoch;

        hideTimer?.cancel();
        hideTimer = Timer(const Duration(milliseconds: 3500), hideControls);
      }

      interceptor.onMouseMove.listen(showControls);
      interceptor.onTouchStart.listen(showControls);

      // 🛡️ DOCKING SHIELD: Never auto-hide while hovering over controls bars
      topBar.onMouseEnter.listen((_) {
        hideTimer?.cancel();
        overlay.classes.add('show-controls');
        interceptor.style.cursor = 'default';
      });
      bottomBar.onMouseEnter.listen((_) {
        hideTimer?.cancel();
        overlay.classes.add('show-controls');
        interceptor.style.cursor = 'default';
      });
      topBar.onMouseLeave.listen((_) {
        hideTimer?.cancel();
        hideTimer = Timer(const Duration(milliseconds: 3500), hideControls);
      });
      bottomBar.onMouseLeave.listen((_) {
        hideTimer?.cancel();
        hideTimer = Timer(const Duration(milliseconds: 3500), hideControls);
      });

      // 📱 Prevent controls auto-hide while interacting with volume slider on mobile touchscreens
      volumeSlider.onTouchStart.listen((_) {
        hideTimer?.cancel();
      });
      volumeSlider.onTouchEnd.listen((_) {
        hideTimer?.cancel();
        hideTimer = Timer(const Duration(milliseconds: 3500), hideControls);
      });

      // 🖱️ SMART SINGLE & DOUBLE CLICK HANDLER
      int lastClickTime = 0;
      Timer? singleClickTimer;

      interceptor.onClick.listen((e) {
        e.preventDefault();
        e.stopPropagation();

        final now = DateTime.now().millisecondsSinceEpoch;
        if (now - lastClickTime < 280) {
          // Double-click -> Toggle fullscreen!
          singleClickTimer?.cancel();
          lastClickTime = 0;
          btnFS.click();
          return;
        }
        lastClickTime = now;

        singleClickTimer?.cancel();
        singleClickTimer = Timer(const Duration(milliseconds: 280), () {
          final nowMs = DateTime.now().millisecondsSinceEpoch;
          final elapsed = nowMs - controlsShownAt;
          if (overlay.classes.contains('show-controls')) {
            // Only hide if controls were shown more than 350ms ago (prevents touchscreen instant dismissal)
            if (elapsed > 350) {
              hideControls();
              hideTimer?.cancel();
            }
          } else {
            showControls(e);
          }
        });
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
        volumeGroup.classes.toggle('active');
      });

      // ⌨️ DIRECT PC/LAPTOP KEYBOARD SHORTCUTS
      html.window.onKeyDown.listen((e) {
        if (wrapper.isConnected != true) return;

        // Skip when typing in an input, textarea or contenteditable element
        final active = html.document.activeElement;
        if (active != null) {
          final tag = active.tagName.toLowerCase();
          if (tag == 'input' ||
              tag == 'textarea' ||
              active.isContentEditable == true ||
              active.classes.contains('flt-text-editing')) {
            return;
          }
        }

        final key = e.key?.toLowerCase() ?? '';
        final code = e.code?.toLowerCase() ?? '';

        if (code == 'space' || key == ' ' || key == 'k' || code == 'keyk') {
          e.preventDefault();
          togglePlay();
        } else if (key == 'f' || code == 'keyf') {
          e.preventDefault();
          btnFS.click();
        } else if (key == 'm' || code == 'keym') {
          e.preventDefault();
          toggleMute();
        } else if (key == 'c' || code == 'keyc') {
          e.preventDefault();
          btnChat.click();
        } else if (key == 'd' || code == 'keyd') {
          e.preventDefault();
          btnDoubts.click();
        } else if (code == 'arrowup' || key == 'arrowup') {
          e.preventDefault();
          setVolume(currentVolume + 5);
          if (currentVolume > 100) {
            showCenterFeedback('⚡ $currentVolume%');
          } else {
            showCenterFeedback(currentVolume == 0 ? '🔇' : (currentVolume < 50 ? '🔉' : '🔊 $currentVolume%'));
          }
        } else if (code == 'arrowdown' || key == 'arrowdown') {
          e.preventDefault();
          setVolume(currentVolume - 5);
          if (currentVolume > 100) {
            showCenterFeedback('⚡ $currentVolume%');
          } else {
            showCenterFeedback(currentVolume == 0 ? '🔇' : (currentVolume < 50 ? '🔉' : '🔊 $currentVolume%'));
          }
        }
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
          btnFS.setInnerHtml('<span>🗗</span> <span class="btn-label">Exit Fullscreen</span> <span class="shortcut-badge">Esc</span>');
          btnFS.title = 'Exit Fullscreen (Esc / F)';
          btnBack.setInnerHtml('<span>🗗</span> <span class="btn-label">Exit Fullscreen</span> <span class="shortcut-badge">Esc</span>');
        } else {
          btnFS.setInnerHtml('<span>⛶</span> <span class="btn-label">Fullscreen</span> <span class="shortcut-badge">F</span>');
          btnFS.title = 'Fullscreen (F) • Double-click video';
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
