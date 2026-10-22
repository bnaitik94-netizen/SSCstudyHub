// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

void pushBrowserUrlImpl(String path) {
  try {
    final current = html.window.location.pathname ?? '';
    final search = html.window.location.search ?? '';
    final fullCurrent = '$current$search';
    if (fullCurrent != path && current != path) {
      html.window.history.pushState(null, '', path);
    }
  } catch (_) {}
}

void replaceBrowserUrlImpl(String path) {
  try {
    html.window.history.replaceState(null, '', path);
  } catch (_) {}
}

String getCurrentBrowserPathImpl() {
  try {
    final path = html.window.location.pathname ?? '/';
    final search = html.window.location.search ?? '';
    return '$path$search';
  } catch (_) {
    return '/';
  }
}

dynamic listenBrowserPopStateImpl(void Function(String path) callback) {
  try {
    return html.window.onPopState.listen((event) {
      final current = getCurrentBrowserPathImpl();
      callback(current);
    });
  } catch (_) {
    return null;
  }
}
