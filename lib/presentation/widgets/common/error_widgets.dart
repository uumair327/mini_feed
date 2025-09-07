import 'package:flutter/material.dart';
import '../../theme/app_breakpoints.dart';
import '../../theme/app_theme_extensions.dart';

/// A reusable error widget with retry functionality
class AppErrorWidget extends StatelessWidget {
  const AppErrorWidget({
    super.key,
    required this.message,
    this.details,
    this.onRetry,
    this.icon = Icons.error_outline,
    this.retryText = 'Retry',
    this.showDetails = false,
  });

  final String message;
  final String? details;
  final VoidCallback? onRetry;
  final IconData icon;
  final String retryText;
  final bool showDetails;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Center(
      child: Padding(
        padding: AppBreakpoints.responsivePadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: AppBreakpoints.responsive(
                context,
                mobile: 64.0,
                tablet: 72.0,
                desktop: 80.0,
              ),
              color: colorScheme.error,
            ),
            SizedBox(
              height: AppBreakpoints.responsive(
                context,
                mobile: 16.0,
                tablet: 20.0,
                desktop: 24.0,
              ),
            ),
            Text(
              message,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            if (details != null && showDetails) ...[
              const SizedBox(height: 8),
              Text(
                details!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              SizedBox(
                height: AppBreakpoints.responsive(
                  context,
                  mobile: 24.0,
                  tablet: 28.0,
                  desktop: 32.0,
                ),
              ),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(retryText),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Network error widget with specific messaging
class NetworkErrorWidget extends StatelessWidget {
  const NetworkErrorWidget({
    super.key,
    this.onRetry,
    this.message = 'No internet connection',
    this.subtitle = 'Please check your connection and try again',
  });

  final VoidCallback? onRetry;
  final String message;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return AppErrorWidget(
      message: message,
      details: subtitle,
      onRetry: onRetry,
      icon: Icons.wifi_off,
      showDetails: true,
    );
  }
}

/// Server error widget for API failures
class ServerErrorWidget extends StatelessWidget {
  const ServerErrorWidget({
    super.key,
    this.onRetry,
    this.message = 'Server error',
    this.subtitle = 'Something went wrong on our end. Please try again later.',
  });

  final VoidCallback? onRetry;
  final String message;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return AppErrorWidget(
      message: message,
      details: subtitle,
      onRetry: onRetry,
      icon: Icons.cloud_off,
      showDetails: true,
    );
  }
}

/// Generic error widget for unexpected errors
class UnexpectedErrorWidget extends StatelessWidget {
  const UnexpectedErrorWidget({
    super.key,
    this.onRetry,
    this.message = 'Something went wrong',
    this.subtitle = 'An unexpected error occurred. Please try again.',
  });

  final VoidCallback? onRetry;
  final String message;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return AppErrorWidget(
      message: message,
      details: subtitle,
      onRetry: onRetry,
      icon: Icons.error_outline,
      showDetails: true,
    );
  }
}

/// Inline error widget for form fields or smaller spaces
class InlineErrorWidget extends StatelessWidget {
  const InlineErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.backgroundColor,
  });

  final String message;
  final VoidCallback? onRetry;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor ?? colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.error.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            size: 20,
            color: colorScheme.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onErrorContainer,
              ),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.error,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 32),
              ),
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Error snackbar for temporary error messages
class ErrorSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: colorScheme.onError,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: colorScheme.onError),
              ),
            ),
          ],
        ),
        backgroundColor: colorScheme.error,
        duration: duration,
        action: actionLabel != null && onAction != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: colorScheme.onError,
                onPressed: onAction,
              )
            : null,
      ),
    );
  }
}

/// Success snackbar for positive feedback
class SuccessSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    final theme = Theme.of(context);
    final appExtension = theme.appExtension;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: appExtension.successColor,
        duration: duration,
      ),
    );
  }
}

/// Warning snackbar for cautionary messages
class WarningSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 4),
  }) {
    final theme = Theme.of(context);
    final appExtension = theme.appExtension;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.warning_outlined,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: appExtension.warningColor,
        duration: duration,
        action: actionLabel != null && onAction != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: onAction,
              )
            : null,
      ),
    );
  }
}