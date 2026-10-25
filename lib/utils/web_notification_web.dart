// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'dart:math';

void requestBrowserNotificationPermissionImpl() {
  try {
    if (html.Notification.supported) {
      if (html.Notification.permission != 'granted' &&
          html.Notification.permission != 'denied') {
        html.Notification.requestPermission();
      }
    }
  } catch (_) {}
}

void showBrowserNotificationImpl(
  String title,
  String body, {
  String? videoId,
  void Function()? onClick,
}) {
  try {
    if (html.Notification.supported &&
        html.Notification.permission == 'granted') {
      final notification = html.Notification(
        title,
        body: body,
        icon: '/favicon.png',
      );

      notification.onClick.listen((_) {
        onClick?.call();
        notification.close();
      });
    }
  } catch (_) {}
}

String getWebClientIdImpl() {
  try {
    var id = html.window.localStorage['ssc_web_client_id'];
    if (id == null || id.isEmpty) {
      final rand = Random().nextInt(999999);
      id = 'web_${DateTime.now().millisecondsSinceEpoch}_$rand';
      html.window.localStorage['ssc_web_client_id'] = id;
    }
    return id;
  } catch (_) {
    return 'web_${DateTime.now().millisecondsSinceEpoch}';
  }
}
