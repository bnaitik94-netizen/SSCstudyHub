import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb; 
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_fonts/google_fonts.dart';
import 'utils/app_colors.dart';
import 'screens/splash_screen.dart';
import 'widgets/connectivity_wrapper.dart';
import 'firebase_options.dart'; 
import 'services/notification_service.dart';
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
    unawaited(NotificationService().initialize());
  } catch (e) {
    debugPrint("Firebase init error: $e");
  }

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
    ]);
  }

  ErrorWidget.builder = (FlutterErrorDetails details) {
    debugPrint("UI Render Error: ${details.exceptionAsString()}");
    return const Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.cosmicBlueDeep,
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline_rounded, color: AppColors.error, size: 56),
                SizedBox(height: 16),
                Text(
                  "Oops! Something went wrong.",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 8),
                Text(
                  "We are working to fix this. Please refresh the app.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
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

class SSCStudyHubApp extends StatelessWidget {
  const SSCStudyHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SSC Study Hub Pro',
      navigatorKey: appNavigatorKey,
      scaffoldMessengerKey: appScaffoldMessengerKey,
      themeMode: ThemeMode.dark,
      builder: (context, child) {
        final mediaQueryData = MediaQuery.of(context);
        final constrainedTextScale = mediaQueryData.textScaler.clamp(minScaleFactor: 0.8, maxScaleFactor: 1.2);
        
        Widget body = ScrollConfiguration(
          behavior: const _PremiumScrollBehavior(),
          child: _PremiumStudyBackground(child: child ?? const SizedBox.shrink()),
        );



        return MediaQuery(
          data: mediaQueryData.copyWith(textScaler: constrainedTextScale),
          child: ConnectivityWrapper(child: body),
        );
      },
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: Colors.transparent,
        canvasColor: Colors.transparent,
        cardColor: AppColors.surfaceDark,
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          centerTitle: true,
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        final uri = Uri.parse(settings.name ?? '/');
        final path = uri.path.toLowerCase();

        if (path == '/home' ||
            path == '/study' ||
            path == '/classes' ||
            path == '/schedule' ||
            path == '/profile' ||
            path == '/live' ||
            path == '/watch' ||
            path == '/player') {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => SplashScreen(
              targetRoute: path,
              queryParams: uri.queryParameters,
            ),
          );
        }

        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const SplashScreen(),
        );
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

class _PremiumScrollBehavior extends ScrollBehavior {
  const _PremiumScrollBehavior();
  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}

class _PremiumStudyBackground extends StatelessWidget {
  final Widget child;
  const _PremiumStudyBackground({required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 🚀 ULTRA-HIGH PERFORMANCE BACKGROUND: Single GPU pass, zero dropped frames
        const RepaintBoundary(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.5, 1.0],
                colors: [
                  AppColors.backgroundTop,
                  AppColors.backgroundMiddle,
                  AppColors.backgroundBottom,
                ],
              ),
            ),
          ),
        ),
        RepaintBoundary(child: child),
      ],
    );
  }
}