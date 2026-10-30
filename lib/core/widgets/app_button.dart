import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

enum _AppButtonVariant { filled, outlined, text }

/// Production-ready accessible button adhering to Material 3 standards.
/// Ensures minimum 48x48dp touch target and visual tactile feedback.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isLoading;
  final bool isFullWidth;
  final _AppButtonVariant _variant;

  const AppButton.filled({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
  }) : _variant = _AppButtonVariant.filled;

  const AppButton.outlined({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
  }) : _variant = _AppButtonVariant.outlined;

  const AppButton.text({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  })  : isLoading = false,
        isFullWidth = false,
        _variant = _AppButtonVariant.text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isInteractive = onPressed != null && !isLoading;

    Widget labelWidget = Text(
      label,
      style: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.1),
    );

    Widget content;
    if (isLoading) {
      final spinnerColor = _variant == _AppButtonVariant.filled
          ? theme.colorScheme.onPrimary
          : theme.colorScheme.primary;

      content = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator.adaptive(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(spinnerColor),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          labelWidget,
        ],
      );
    } else if (icon != null) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon!,
          const SizedBox(width: AppSpacing.sm),
          labelWidget,
        ],
      );
    } else {
      content = labelWidget;
    }

    Widget button;
    switch (_variant) {
      case _AppButtonVariant.filled:
        button = FilledButton(
          onPressed: isInteractive ? onPressed : null,
          child: content,
        );
        break;
      case _AppButtonVariant.outlined:
        button = OutlinedButton(
          onPressed: isInteractive ? onPressed : null,
          child: content,
        );
        break;
      case _AppButtonVariant.text:
        button = TextButton(
          onPressed: isInteractive ? onPressed : null,
          child: content,
        );
        break;
    }

    if (isFullWidth) {
      button = SizedBox(width: double.infinity, child: button);
    }

    return Semantics(
      button: true,
      enabled: isInteractive,
      label: label,
      child: button,
    );
  }
}
