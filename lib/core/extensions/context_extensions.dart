import 'package:flutter/material.dart';

/// Convenient BuildContext shortcuts for clean, readable UI code.
extension ContextExtensions on BuildContext {
  // Theme shortcuts
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;

  // Brightness shortcut
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  // MediaQuery shortcuts
  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;
  EdgeInsets get padding => MediaQuery.paddingOf(this);

  // SnackBar helper
  void showAppSnackBar(
    String message, {
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(this).hideCurrentSnackBar();
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? colorScheme.error : colorScheme.inverseSurface,
        duration: duration,
        action: action,
      ),
    );
  }
}
