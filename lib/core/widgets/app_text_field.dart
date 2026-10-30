import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

/// Studio-grade Input Field:
/// - Custom InputDecoration without default underline.
/// - Floating label with smooth color transition on focus.
/// - 1.5px border transitioning from surface variant to primary accent.
/// - Error state with horizontal shake micro-animation (Curves.easeOutCubic).
/// - Password toggle with animated visibility icon.
class AppTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? errorText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool isPassword;
  final bool autofocus;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? Function(String?)? validator;
  final int maxLines;
  final bool enabled;

  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.isPassword = false,
    this.autofocus = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.maxLines = 1,
    this.enabled = true,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> with SingleTickerProviderStateMixin {
  late FocusNode _focusNode;
  bool _isFocused = false;
  bool _obscureText = true;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _shakeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
    );

    if (widget.errorText != null && widget.errorText!.isNotEmpty) {
      _shakeController.forward(from: 0.0);
    }
  }

  @override
  void didUpdateWidget(covariant AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.errorText != null &&
        widget.errorText!.isNotEmpty &&
        widget.errorText != oldWidget.errorText) {
      _shakeController.forward(from: 0.0);
    }
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() => _isFocused = _focusNode.hasFocus);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    // Resolve border color
    Color borderColor;
    if (hasError) {
      borderColor = AppColors.error;
    } else if (_isFocused) {
      borderColor = AppColors.primaryAccent;
    } else {
      borderColor = isDark ? AppColors.surfaceVariantDark : AppColors.surfaceHighLight;
    }

    // Resolve background fill
    final fillColor = isDark ? AppColors.surfaceDark : AppColors.surfaceVariantLight;

    Widget suffix = widget.suffixIcon ?? const SizedBox.shrink();
    if (widget.isPassword) {
      suffix = IconButton(
        icon: Icon(
          _obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          size: 20,
          color: _isFocused ? AppColors.primaryAccent : theme.colorScheme.onSurfaceVariant,
        ),
        onPressed: () {
          setState(() => _obscureText = !_obscureText);
        },
      );
    }

    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        // Shake offset formula
        final double offset = hasError
            ? math.sin(_shakeAnimation.value * math.pi * 4) * 6 * (1.0 - _shakeAnimation.value)
            : 0.0;

        return Transform.translate(
          offset: Offset(offset, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  color: fillColor,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                    color: borderColor,
                    width: _isFocused || hasError ? 1.8 : 1.2,
                  ),
                ),
                child: TextFormField(
                  focusNode: _focusNode,
                  controller: widget.controller,
                  autofocus: widget.autofocus,
                  obscureText: _obscureText,
                  keyboardType: widget.keyboardType,
                  textInputAction: widget.textInputAction,
                  onChanged: widget.onChanged,
                  onFieldSubmitted: widget.onSubmitted,
                  validator: widget.validator,
                  maxLines: widget.maxLines,
                  enabled: widget.enabled,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    labelText: widget.label,
                    hintText: widget.hint,
                    floatingLabelBehavior: FloatingLabelBehavior.auto,
                    floatingLabelStyle: TextStyle(
                      color: hasError
                          ? AppColors.error
                          : (_isFocused ? AppColors.primaryAccent : theme.colorScheme.onSurfaceVariant),
                      fontWeight: FontWeight.w600,
                    ),
                    labelStyle: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                    hintStyle: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
                      fontSize: 14,
                    ),
                    prefixIcon: widget.prefixIcon != null
                        ? IconTheme(
                            data: IconThemeData(
                              color: _isFocused
                                  ? AppColors.primaryAccent
                                  : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                              size: 20,
                            ),
                            child: widget.prefixIcon!,
                          )
                        : null,
                    suffixIcon: widget.isPassword || widget.suffixIcon != null ? suffix : null,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.md,
                    ),
                  ),
                ),
              ),
              if (hasError) ...[
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Text(
                    widget.errorText!,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
