// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:js' as js;
import 'dart:async';

class WebFullscreenHelper {
  static bool isFullscreen() {
    try {
      final doc = html.document;
      if (doc.fullscreenElement != null) return true;
      final result = js.context.callMethod('isAppFullscreen');
      return result == true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> enterFullscreen() async {
    try {
      js.context.callMethod('requestAppFullscreen');
      return;
    } catch (_) {}
    try {
      final elem = html.document.documentElement;
      if (elem != null) {
        elem.requestFullscreen();
        try {
          // ignore: avoid_dynamic_calls
          (html.window.screen as dynamic)?.orientation?.lock('landscape');
        } catch (_) {}
        return;
      }
    } catch (_) {}
  }

  static Future<void> exitFullscreen() async {
    try {
      js.context.callMethod('exitAppFullscreen');
      return;
    } catch (_) {}
    try {
      try {
        // ignore: avoid_dynamic_calls
        (html.window.screen as dynamic)?.orientation?.unlock();
      } catch (_) {}
      if (isFullscreen()) {
        html.document.exitFullscreen();
        return;
      }
    } catch (_) {}
  }

  static Future<void> toggleFullscreen() async {
    if (isFullscreen()) {
      await exitFullscreen();
    } else {
      await enterFullscreen();
    }
  }

  static StreamSubscription? listenFullscreenChange(void Function(bool isFullscreen) onChange) {
    try {
      return html.document.onFullscreenChange.listen((_) {
        onChange(isFullscreen());
      });
    } catch (_) {
      return null;
    }
  }

  static void sendVideoCommand(String command, [List<dynamic>? args]) {
    try {
      js.context.callMethod('sendYouTubePlayerCommand', [command, args ?? []]);
    } catch (_) {}
  }

  static StreamSubscription? listenVideoHover(void Function() onHover) {
    try {
      return html.window.on['app-video-hover'].listen((_) {
        onHover();
      });
    } catch (_) {
      return null;
    }
  }

  static StreamSubscription? listenVideoTap(void Function() onTap) {
    try {
      return html.window.on['app-video-tap'].listen((_) {
        onTap();
      });
    } catch (_) {
      return null;
    }
  }

  static StreamSubscription? listenVideoDoubleTap(void Function() onDoubleTap) {
    try {
      return html.window.on['app-video-double-tap'].listen((_) {
        onDoubleTap();
      });
    } catch (_) {
      return null;
    }
  }

  static StreamSubscription? listenPlayerBack(void Function() onBack) {
    try {
      return html.window.on['app-player-back'].listen((_) => onBack());
    } catch (_) {
      return null;
    }
  }

  static StreamSubscription? listenPlayerSync(void Function() onSync) {
    try {
      return html.window.on['app-player-sync'].listen((_) => onSync());
    } catch (_) {
      return null;
    }
  }

  static StreamSubscription? listenPlayerFullscreen(void Function() onFullscreen) {
    try {
      return html.window.on['app-player-fullscreen'].listen((_) => onFullscreen());
    } catch (_) {
      return null;
    }
  }

  static StreamSubscription? listenPlayerChat(void Function() onChat) {
    try {
      return html.window.on['app-player-chat'].listen((_) => onChat());
    } catch (_) {
      return null;
    }
  }

  static StreamSubscription? listenPlayerDoubts(void Function() onDoubts) {
    try {
      return html.window.on['app-player-doubts'].listen((_) => onDoubts());
    } catch (_) {
      return null;
    }
  }

  static void dispatchSpawnEmoji(String emoji) {
    try {
      html.window.dispatchEvent(html.CustomEvent('app-spawn-emoji', detail: emoji));
    } catch (_) {}
  }

  static StreamSubscription? listenSpawnEmoji(void Function(String emoji) onEmoji) {
    try {
      return html.window.on['app-spawn-emoji'].listen((event) {
        if (event is html.CustomEvent && event.detail != null) {
          onEmoji(event.detail.toString());
        }
      });
    } catch (_) {
      return null;
    }
  }
}
