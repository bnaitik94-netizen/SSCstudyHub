import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    // Mobile fallback
    return web; 
  }

  // Your exact credentials extracted from index.html
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDvJF-19NLwk5rvVRTl8jE0zxa3sCSwrIY',
    appId: '1:40811673099:web:f9a0405369e52c891bb90e',
    messagingSenderId: '40811673099',
    projectId: 'naitik-live-class',
    authDomain: 'naitik-live-class.firebaseapp.com',
    storageBucket: 'naitik-live-class.appspot.com',
  );
}