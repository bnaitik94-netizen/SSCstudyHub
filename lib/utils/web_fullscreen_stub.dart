import 'dart:async';

class WebFullscreenHelper {
  static bool isFullscreen() => false;
  static Future<void> enterFullscreen() async {}
  static Future<void> exitFullscreen() async {}
  static Future<void> toggleFullscreen() async {}
  static StreamSubscription? listenFullscreenChange(void Function(bool isFullscreen) onChange) => null;
  static void sendVideoCommand(String command, [List<dynamic>? args]) {}
  static StreamSubscription? listenVideoHover(void Function() onHover) => null;
  static StreamSubscription? listenVideoTap(void Function() onTap) => null;
  static StreamSubscription? listenVideoDoubleTap(void Function() onDoubleTap) => null;
  static StreamSubscription? listenPlayerBack(void Function() onBack) => null;
  static StreamSubscription? listenPlayerSync(void Function() onSync) => null;
  static StreamSubscription? listenPlayerFullscreen(void Function() onFullscreen) => null;
  static StreamSubscription? listenPlayerChat(void Function() onChat) => null;
  static StreamSubscription? listenPlayerDoubts(void Function() onDoubts) => null;
  static void dispatchSpawnEmoji(String emoji) {}
  static StreamSubscription? listenSpawnEmoji(void Function(String emoji) onEmoji) => null;
}
