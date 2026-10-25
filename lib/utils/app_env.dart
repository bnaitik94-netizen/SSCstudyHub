/// Centralized Application Environment Configuration
/// Reads values injected via `--dart-define` or `--dart-define-from-file=.env`
/// with production-safe fallbacks for offline or standalone builds.
class AppEnv {
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'AIzaSyDvJF-19NLwk5rvVRTl8jE0zxa3sCSwrIY',
  );

  static const String firebaseApiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: 'AIzaSyDvJF-19NLwk5rvVRTl8jE0zxa3sCSwrIY',
  );

  static const String firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'naitik-live-class',
  );

  static const String firebaseMessagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
    defaultValue: '40811673099',
  );

  static const String firebaseAuthDomain = String.fromEnvironment(
    'FIREBASE_AUTH_DOMAIN',
    defaultValue: 'naitik-live-class.firebaseapp.com',
  );

  static const String firebaseStorageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
    defaultValue: 'naitik-live-class.appspot.com',
  );

  static const String firebaseAppIdWeb = String.fromEnvironment(
    'FIREBASE_APP_ID_WEB',
    defaultValue: '1:40811673099:web:f9a0405369e52c891bb90e',
  );

  static const String firebaseAppIdAndroid = String.fromEnvironment(
    'FIREBASE_APP_ID_ANDROID',
    defaultValue: '1:40811673099:android:9f65b53bd93bf18d1bb90e',
  );
}
