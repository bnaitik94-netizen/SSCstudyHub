import 'web_notification_stub.dart'
    if (dart.library.html) 'web_notification_web.dart';

class WebNotificationHelper {
  /// Request browser notification permission if running on web
  static void requestPermission() {
    requestBrowserNotificationPermissionImpl();
  }

  /// Show browser notification when running on web
  static void showNotification(
    String title,
    String body, {
    String? videoId,
    void Function()? onClick,
  }) {
    showBrowserNotificationImpl(
      title,
      body,
      videoId: videoId,
      onClick: onClick,
    );
  }

  /// Get or create persistent Web client ID
  static String getWebClientId() {
    return getWebClientIdImpl();
  }
}
