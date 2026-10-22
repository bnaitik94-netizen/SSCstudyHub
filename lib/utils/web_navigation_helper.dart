import 'web_navigation_stub.dart'
    if (dart.library.html) 'web_navigation_web.dart';

class WebNavigationHelper {
  /// Update browser URL in address bar (e.g. /home, /study, /classes, /profile)
  static void updateUrl(String path) {
    pushBrowserUrlImpl(path);
  }

  /// Replace current browser URL without pushing new history entry
  static void replaceUrl(String path) {
    replaceBrowserUrlImpl(path);
  }

  /// Get current browser path and query
  static String get currentPath => getCurrentBrowserPathImpl();

  /// Listen for browser Back/Forward navigation
  static dynamic listenPopState(void Function(String path) callback) {
    return listenBrowserPopStateImpl(callback);
  }
}
