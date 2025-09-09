import 'package:flutter/material.dart';

import '../../../core/errors/failures.dart';
import '../../../core/error_handling/global_error_handler.dart';

/// Comprehensive error widget that handles different types of errors
class ComprehensiveErrorWidget extends StatelessWidget {
  final String message;
  final String? details;
  final VoidCallback? onRetry;
  final bool canRetry;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const ComprehensiveErrorWidget({
    super.key,
    required this.message,
    this.details,
    this.onRetry,
    this.canRetry = true,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  /// Create error widget from failure
  factory ComprehensiveErrorWidget.fromFailure(
    Failure failure, {
    VoidCallback? onRetry,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return ComprehensiveErrorWidget(
      message: _getMessageFromFailure(failure),
      details: failure.message,
      onRetry: onRetry,
      canRetry: _isRetryableFailure(failure),
      icon: _getIconFromFailure(failure),
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Create error widget from exception
  factory ComprehensiveErrorWidget.fromException(
    Object exception, {
    VoidCallback? onRetry,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final failure = GlobalErrorHandler.handleException(exception);
    return ComprehensiveErrorWidget.fromFailure(
      failure,
      onRetry: onRetry,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error icon
            Icon(
              icon ?? Icons.error_outline,
              size: 64,
              color: colorScheme.error,
            ),
            
            const SizedBox(height: 16),
            
            // Error message
            Text(
              message,
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            
            // Details (if provided and in debug mode)
            if (details != null && details!.isNotEmpty) ...[
              const SizedBox(height: 8),
              ExpansionTile(
                title: Text(
                  'Technical Details',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SelectableText(
                      details!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            
            const SizedBox(height: 24),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Retry button
                if (canRetry && onRetry != null) ...[
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                    ),
                  ),
                  
                  if (onAction != null) const SizedBox(width: 12),
                ],
                
                // Custom action button
                if (onAction != null)
                  OutlinedButton(
                    onPressed: onAction,
                    child: Text(actionLabel ?? 'Action'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _getMessageFromFailure(Failure failure) {
    if (failure is NetworkFailure) {
      final message = failure.message.toLowerCase();
      if (message.contains('internet') || message.contains('connection')) {
        return 'No internet connection available.\nPlease check your network settings.';
      } else if (message.contains('timeout')) {
        return 'Request timed out.\nPlease try again.';
      } else if (message.contains('server')) {
        return 'Server is temporarily unavailable.\nPlease try again later.';
      } else if (message.contains('unauthorized')) {
        return 'Authentication required.\nPlease log in again.';
      } else if (message.contains('forbidden')) {
        return 'Access denied.\nYou don\'t have permission for this action.';
      } else if (message.contains('not found')) {
        return 'The requested content was not found.';
      } else {
        return 'Network error occurred.\nPlease check your connection.';
      }
    } else if (failure is AuthFailure) {
      final message = failure.message.toLowerCase();
      if (message.contains('credentials') || message.contains('password')) {
        return 'Invalid email or password.\nPlease check your credentials.';
      } else if (message.contains('expired') || message.contains('session')) {
        return 'Your session has expired.\nPlease log in again.';
      } else if (message.contains('disabled')) {
        return 'Your account has been disabled.\nPlease contact support.';
      } else {
        return 'Authentication error occurred.\nPlease try logging in again.';
      }
    } else if (failure is CacheFailure) {
      return 'Data loading error occurred.\nPlease try refreshing.';
    } else if (failure is ValidationFailure) {
      return 'Invalid input provided.\nPlease check your data and try again.';
    } else {
      return 'Something went wrong.\nPlease try again.';
    }
  }

  static IconData _getIconFromFailure(Failure failure) {
    if (failure is NetworkFailure) {
      final message = failure.message.toLowerCase();
      if (message.contains('internet') || message.contains('connection')) {
        return Icons.wifi_off;
      } else if (message.contains('timeout')) {
        return Icons.access_time;
      } else if (message.contains('server')) {
        return Icons.dns;
      } else if (message.contains('unauthorized') || message.contains('forbidden')) {
        return Icons.lock;
      } else if (message.contains('not found')) {
          return Icons.search_off;
      } else {
        return Icons.cloud_off;
      }
    } else if (failure is AuthFailure) {
      return Icons.person_off;
    } else if (failure is CacheFailure) {
      return Icons.storage;
    } else if (failure is ValidationFailure) {
      return Icons.warning;
    } else {
      return Icons.error_outline;
    }
  }

  static bool _isRetryableFailure(Failure failure) {
    if (failure is NetworkFailure) {
      final message = failure.message.toLowerCase();
      if (message.contains('internet') || message.contains('timeout') || message.contains('server')) {
        return true;
      } else if (message.contains('unauthorized') || message.contains('forbidden') || message.contains('not found')) {
        return false;
      } else {
        return true;
      }
    } else if (failure is AuthFailure) {
      return !failure.message.toLowerCase().contains('disabled');
    } else if (failure is CacheFailure) {
      return true;
    } else if (failure is ValidationFailure) {
      return false;
    } else {
      return true;
    }
  }
}

/// Compact error widget for smaller spaces
class CompactErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final bool canRetry;

  const CompactErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.canRetry = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: colorScheme.error,
            size: 20,
          ),
          
          const SizedBox(width: 12),
          
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ),
          
          if (canRetry && onRetry != null) ...[
            const SizedBox(width: 12),
            TextButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Error snackbar helper
class ErrorSnackBar {
  static void show(
    BuildContext context,
    String message, {
    VoidCallback? onRetry,
    Duration duration = const Duration(seconds: 4),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: duration,
        action: onRetry != null
            ? SnackBarAction(
                label: 'Retry',
                onPressed: onRetry,
                textColor: Theme.of(context).colorScheme.onError,
              )
            : null,
      ),
    );
  }

  static void showFromFailure(
    BuildContext context,
    Failure failure, {
    VoidCallback? onRetry,
    Duration duration = const Duration(seconds: 4),
  }) {
    final message = ComprehensiveErrorWidget._getMessageFromFailure(failure);
    final canRetry = ComprehensiveErrorWidget._isRetryableFailure(failure);
    
    show(
      context,
      message,
      onRetry: canRetry ? onRetry : null,
      duration: duration,
    );
  }
}