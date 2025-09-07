import 'package:flutter/material.dart';
import '../../theme/app_theme_extensions.dart';

/// Minimum touch target size for accessibility compliance
const double kMinTouchTargetSize = 44.0;

/// A button with accessibility-compliant minimum touch target size
class AccessibleButton extends StatelessWidget {
  const AccessibleButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.semanticLabel,
    this.tooltip,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final String? semanticLabel;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    Widget button = ElevatedButton(
      onPressed: onPressed,
      child: child,
    );

    button = ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: kMinTouchTargetSize,
        minHeight: kMinTouchTargetSize,
      ),
      child: button,
    );

    if (tooltip != null) {
      button = Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    if (semanticLabel != null) {
      button = Semantics(
        label: semanticLabel,
        button: true,
        child: button,
      );
    }

    return button;
  }
}

/// An icon button with accessibility-compliant minimum touch target size
class AccessibleIconButton extends StatelessWidget {
  const AccessibleIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.semanticLabel,
    this.tooltip,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String? semanticLabel;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    Widget button = IconButton(
      onPressed: onPressed,
      icon: Icon(icon),
      iconSize: 24,
      constraints: const BoxConstraints(
        minWidth: kMinTouchTargetSize,
        minHeight: kMinTouchTargetSize,
      ),
      tooltip: tooltip,
    );

    if (semanticLabel != null) {
      button = Semantics(
        label: semanticLabel,
        button: true,
        child: button,
      );
    }

    return button;
  }
}

/// A text field with accessibility enhancements
class AccessibleTextField extends StatelessWidget {
  const AccessibleTextField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.enabled = true,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.onFieldSubmitted,
    this.semanticLabel,
  });

  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool enabled;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onFieldSubmitted;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    Widget textField = TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      enabled: enabled,
      validator: validator,
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffixIcon: suffixIcon,
        border: const OutlineInputBorder(),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.error,
            width: 2,
          ),
        ),
      ),
    );

    if (semanticLabel != null) {
      textField = Semantics(
        label: semanticLabel,
        textField: true,
        child: textField,
      );
    }

    return textField;
  }
}