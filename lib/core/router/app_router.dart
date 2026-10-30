import 'package:flutter/material.dart';
import '../../screens/splash_screen.dart';

/// App routing and standardized Material 3 page transitions.
class AppRouter {
  static const String splash = '/';
  static const String home = '/home';
  static const String study = '/study';
  static const String classes = '/classes';
  static const String schedule = '/schedule';
  static const String profile = '/profile';
  static const String live = '/live';
  static const String watch = '/watch';
  static const String player = '/player';

  /// Standard slide-from-right transition for forward navigation.
  static Route<T> slideRight<T>({
    required Widget page,
    RouteSettings? settings,
    Duration duration = const Duration(milliseconds: 250),
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final tween = Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }

  /// Fade transition for modal or overlay navigation.
  static Route<T> fade<T>({
    required Widget page,
    RouteSettings? settings,
    Duration duration = const Duration(milliseconds: 200),
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
          child: child,
        );
      },
    );
  }

  /// Generate routes matching clean HTML5 URLs & deep links.
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final uri = Uri.parse(settings.name ?? splash);
    final path = uri.path.toLowerCase();

    if (path == home ||
        path == study ||
        path == classes ||
        path == schedule ||
        path == profile ||
        path == live ||
        path == watch ||
        path == player) {
      return slideRight(
        settings: settings,
        page: SplashScreen(
          targetRoute: path,
          queryParams: uri.queryParameters,
        ),
      );
    }

    return fade(
      settings: settings,
      page: const SplashScreen(),
    );
  }
}
