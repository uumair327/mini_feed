import 'package:flutter/material.dart';
import '../../theme/app_breakpoints.dart';
import 'accessibility_widgets.dart';

/// Primary button with consistent styling
class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.icon,
    this.isLoading = false,
    this.isExpanded = false,
    this.semanticLabel,
  });

  final VoidCallback? onPressed;
  final String text;
  final IconData? icon;
  final bool isLoading;
  final bool isExpanded;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    Widget button;
    
    if (icon != null) {
      button = ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading 
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon),
        label: Text(text),
      );
    } else {
      button = ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(text),
      );
    }

    if (isExpanded) {
      button = SizedBox(
        width: double.infinity,
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

/// Secondary button with consistent styling
class AppSecondaryButton extends StatelessWidget {
  const AppSecondaryButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.icon,
    this.isLoading = false,
    this.isExpanded = false,
    this.semanticLabel,
  });

  final VoidCallback? onPressed;
  final String text;
  final IconData? icon;
  final bool isLoading;
  final bool isExpanded;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    Widget button;
    
    if (icon != null) {
      button = OutlinedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading 
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon),
        label: Text(text),
      );
    } else {
      button = OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(text),
      );
    }

    if (isExpanded) {
      button = SizedBox(
        width: double.infinity,
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

/// Text button with consistent styling
class AppTextButton extends StatelessWidget {
  const AppTextButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.icon,
    this.semanticLabel,
  });

  final VoidCallback? onPressed;
  final String text;
  final IconData? icon;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    Widget button;
    
    if (icon != null) {
      button = TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(text),
      );
    } else {
      button = TextButton(
        onPressed: onPressed,
        child: Text(text),
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

/// Responsive button that adapts to screen size
class ResponsiveButton extends StatelessWidget {
  const ResponsiveButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.icon,
    this.type = ButtonType.primary,
    this.isLoading = false,
    this.semanticLabel,
  });

  final VoidCallback? onPressed;
  final String text;
  final IconData? icon;
  final ButtonType type;
  final bool isLoading;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final isExpanded = AppBreakpoints.isMobile(context);
    
    switch (type) {
      case ButtonType.primary:
        return AppPrimaryButton(
          onPressed: onPressed,
          text: text,
          icon: icon,
          isLoading: isLoading,
          isExpanded: isExpanded,
          semanticLabel: semanticLabel,
        );
      case ButtonType.secondary:
        return AppSecondaryButton(
          onPressed: onPressed,
          text: text,
          icon: icon,
          isLoading: isLoading,
          isExpanded: isExpanded,
          semanticLabel: semanticLabel,
        );
      case ButtonType.text:
        return AppTextButton(
          onPressed: onPressed,
          text: text,
          icon: icon,
          semanticLabel: semanticLabel,
        );
    }
  }
}

enum ButtonType {
  primary,
  secondary,
  text,
}