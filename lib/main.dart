import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb; 
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'core/router/app_router.dart';
import 'widgets/connectivity_wrapper.dart';
import 'firebase_options.dart'; 
import 'services/notification_service.dart';
import 'services/background_music_service.dart';
import 'utils/url_strategy_helper.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> appScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }
  debugPrint("Background message handled: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🌐 Enable clean HTML5 web URL routing (/home, /study, /classes, /live)
  setupUrlStrategy();

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    
    // Background & foreground messaging initialization
    NotificationService.navigatorKey = appNavigatorKey;
    NotificationService.scaffoldMessengerKey = appScaffoldMessengerKey;
    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    }
    // PERF: Non-blocking background notification initialization
    unawaited(NotificationService().initialize());
  } catch (e) {
    debugPrint("Firebase init error: $e");
  }

  // 🎵 Start Invisible Background Music Service
  unawaited(BackgroundMusicService.instance.startAutoMusic());

  if (!kIsWeb) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  ErrorWidget.builder = (FlutterErrorDetails details) {
    debugPrint("UI Render Error: ${details.exceptionAsString()}");
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.surfaceLowestDark,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 56),
                const SizedBox(height: 16),
                const Text(
                  "Oops! Something went wrong.",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  "We are working to fix this. Please refresh the app.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  };

  runApp(const SSCStudyHubApp());
}

class SSCStudyHubApp extends StatefulWidget {
  const SSCStudyHubApp({super.key});

  @override
  State<SSCStudyHubApp> createState() => _SSCStudyHubAppState();
}

class _SSCStudyHubAppState extends State<SSCStudyHubApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    try {
      // 🎵 Auto pause background music when app is minimized / backgrounded
      if (state == AppLifecycleState.paused ||
          state == AppLifecycleState.inactive ||
          state == AppLifecycleState.hidden) {
        BackgroundMusicService.instance.onAppMinimized();
      } else if (state == AppLifecycleState.resumed) {
        // 🎵 Auto resume background music when coming back to foreground
        BackgroundMusicService.instance.onAppResumed();
      }
    } catch (e) {
      debugPrint('[Lifecycle] Error handling state $state: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SSC Study Hub Pro',
      navigatorKey: appNavigatorKey,
      scaffoldMessengerKey: appScaffoldMessengerKey,
      themeMode: ThemeMode.dark,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      builder: (context, child) {
        final mediaQueryData = MediaQuery.of(context);
        final constrainedTextScale = mediaQueryData.textScaler.clamp(minScaleFactor: 0.8, maxScaleFactor: 1.2);
        
        // PERF: Wrap in RepaintBoundary and optimize scroll behavior for 60fps
        Widget body = ScrollConfiguration(
          behavior: const _AppScrollBehavior(),
          child: Container(
            color: Theme.of(context).colorScheme.surface,
            child: child ?? const SizedBox.shrink(),
          ),
        );

        return MediaQuery(
          data: mediaQueryData.copyWith(textScaler: constrainedTextScale),
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (_) {
              BackgroundMusicService.instance.onUserInteraction();
            },
            child: ConnectivityWrapper(child: body),
          ),
        );
      },
      initialRoute: AppRouter.splash,
      onGenerateRoute: AppRouter.onGenerateRoute,
      debugShowCheckedModeBanner: false,
    );
  }
}

class _AppScrollBehavior extends ScrollBehavior {
  const _AppScrollBehavior();
  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}
