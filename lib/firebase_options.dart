import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'utils/app_env.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    // Mobile fallback
    return web; 
  }

  // Credentials configured from AppEnv (.env or production fallback)
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: AppEnv.firebaseApiKey,
    appId: AppEnv.firebaseAppIdWeb,
    messagingSenderId: AppEnv.firebaseMessagingSenderId,
    projectId: AppEnv.firebaseProjectId,
    authDomain: AppEnv.firebaseAuthDomain,
    storageBucket: AppEnv.firebaseStorageBucket,
  );
}
