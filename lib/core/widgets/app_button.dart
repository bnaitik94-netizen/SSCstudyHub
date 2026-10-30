import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

enum _AppButtonVariant { primaryCta, filled, secondaryOutlined, destructive, text, iconOnly }

/// Master Button System engineered for tactile feedback, minimum 48dp/44dp tap targets,
/// and smooth studio-grade micro-animations (InkWell > ElevatedButton).
class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isLoading;
  final bool isFullWidth;
  final double height;
  final _AppButtonVariant _variant;

  // Icon only props
  final IconData? iconData;
  final String? tooltip;

  /// Primary CTA: Full-width, gradient fill, pill shape, 56px height
  const AppButton.primaryCta({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
    this.height = 56.0,
  })  : _variant = _AppButtonVariant.primaryCta,
        iconData = null,
        tooltip = null;

  /// Standard filled button (52px height)
  const AppButton.filled({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.height = 50.0,
  })  : _variant = _AppButtonVariant.filled,
        iconData = null,
        tooltip = null;

  /// Secondary outlined button with press feedback
  const AppButton.outlined({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.height = 50.0,
  })  : _variant = _AppButtonVariant.secondaryOutlined,
        iconData = null,
        tooltip = null;

  /// Secondary alias
  const AppButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.height = 50.0,
  })  : _variant = _AppButtonVariant.secondaryOutlined,
        iconData = null,
        tooltip = null;

  /// Destructive action button (red tint surface, no gradient)
  const AppButton.destructive({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.height = 50.0,
  })  : _variant = _AppButtonVariant.destructive,
        iconData = null,
        tooltip = null;

  /// Clean text button
  const AppButton.text({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  })  : isLoading = false,
        isFullWidth = false,
        height = 44.0,
        _variant = _AppButtonVariant.text,
        iconData = null,
        tooltip = null;

  /// Tactile Icon Button with min 44x44dp touch target and press scale
  const AppButton.iconButton({
    super.key,
    required IconData icon,
    required this.onPressed,
    this.tooltip,
  })  : label = '',
        icon = null,
        iconData = icon,
        isLoading = false,
        isFullWidth = false,
        height = 44.0,
        _variant = _AppButtonVariant.iconOnly;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _isPressed = false;

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      setState(() => _isPressed = true);
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (_isPressed) setState(() => _isPressed = false);
  }

  void _onTapCancel() {
    if (_isPressed) setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEnabled = widget.onPressed != null && !widget.isLoading;

    if (widget._variant == _AppButtonVariant.iconOnly) {
      Widget iconBtn = AnimatedScale(
        scale: _isPressed ? 0.90 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: widget.onPressed,
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            splashColor: AppColors.primaryAccent.withValues(alpha: 0.15),
            child: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              child: Icon(
                widget.iconData,
                size: 20,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
      );

      if (widget.tooltip != null) {
        return Tooltip(message: widget.tooltip!, child: iconBtn);
      }
      return iconBtn;
    }

    // Label & Loading state
    Widget content;
    if (widget.isLoading) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                widget._variant == _AppButtonVariant.primaryCta || widget._variant == _AppButtonVariant.filled
                    ? Colors.white
                    : theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            widget.label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      );
    } else {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.icon != null) ...[
            widget.icon!,
            const SizedBox(width: AppSpacing.sm),
          ],
          Text(
            widget.label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: widget._variant == _AppButtonVariant.primaryCta ? 16 : 14,
              letterSpacing: 0.2,
            ),
          ),
        ],
      );
    }

    // Styling per variant
    BoxDecoration decoration;
    Color textColor;

    switch (widget._variant) {
      case _AppButtonVariant.primaryCta:
        textColor = Colors.white;
        decoration = BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          gradient: isEnabled
              ? const LinearGradient(
                  colors: [
                    AppColors.primaryAccent,
                    Color(0xFF818CF8), // Studio Indigo-Violet
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isEnabled ? null : theme.colorScheme.surfaceContainerHighest,
          boxShadow: isEnabled && isDark
              ? [
                  BoxShadow(
                    color: AppColors.primaryAccent.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        );
        break;

      case _AppButtonVariant.filled:
        textColor = Colors.white;
        decoration = BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          color: isEnabled ? AppColors.primaryAccent : theme.colorScheme.surfaceContainerHighest,
        );
        break;

      case _AppButtonVariant.secondaryOutlined:
        textColor = isEnabled ? theme.colorScheme.onSurface : theme.disabledColor;
        decoration = BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          color: Colors.transparent,
          border: Border.all(
            color: isEnabled
                ? (_isPressed ? AppColors.primaryAccent : theme.colorScheme.outline)
                : theme.disabledColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
        );
        break;

      case _AppButtonVariant.destructive:
        textColor = AppColors.error;
        decoration = BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          color: AppColors.error.withValues(alpha: 0.12),
          border: Border.all(
            color: AppColors.error.withValues(alpha: 0.3),
            width: 1,
          ),
        );
        break;

      case _AppButtonVariant.text:
        textColor = isEnabled ? AppColors.primaryAccent : theme.disabledColor;
        decoration = const BoxDecoration();
        break;

      default:
        textColor = theme.colorScheme.onSurface;
        decoration = const BoxDecoration();
    }

    Widget buttonBody = AnimatedScale(
      scale: _isPressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: Container(
        height: widget.height,
        width: widget.isFullWidth ? double.infinity : null,
        decoration: decoration,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
            onTap: isEnabled ? widget.onPressed : null,
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            splashColor: Colors.white.withValues(alpha: 0.15),
            highlightColor: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: DefaultTextStyle(
                style: TextStyle(color: textColor),
                child: Center(child: content),
              ),
            ),
          ),
        ),
      ),
    );

    return RepaintBoundary(child: buttonBody);
  }
}
