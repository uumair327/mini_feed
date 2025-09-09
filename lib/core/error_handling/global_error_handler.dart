import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../utils/logger.dart';
import '../errors/exceptions.dart';
import '../errors/failures.dart';

/// Global error handler for the application
class GlobalErrorHandler {
  static GlobalErrorHandler? _instance;
  static GlobalErrorHandler get instance => _instance ??= GlobalErrorHandler._();
  
  GlobalErrorHandler._();

  /// Initialize global error handling
  static void initialize() {
    // Handle Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      Logger.error('Flutter Error', details.exception);
      if (kDebugMode) {
        FlutterError.presentError(details);
      } else {
        _reportError(details.exception, details.stack);
      }
    };

    // Handle async errors
    PlatformDispatcher.instance.onError = (error, stack) {
      Logger.error('Async Error', error);
      _reportError(error, stack);
      return true;
    };

    // Handle zone errors
    runZonedGuarded(() {
      // App initialization happens here
    }, (error, stack) {
      Logger.error('Zone Error', error);
      _reportError(error, stack);
    });
  }

  /// Report error to crash reporting service
  static void _reportError(Object error, StackTrace? stack) {
    // In a real app, you would send this to a crash reporting service
    // like Firebase Crashlytics, Sentry, etc.
    Logger.error('Reporting error to crash service', error);
    
    if (stack != null) {
      Logger.error('Stack trace', stack);
    }
  }

  /// Handle and convert exceptions to user-friendly failures
  static Failure handleException(Object exception) {
    Logger.error('Handling exception', exception);

    if (exception is NetworkException) {
      return NetworkFailure(exception.message);
    } else if (exception is CacheException) {
      return CacheFailure(exception.message);
    } else if (exception is AuthException) {
      return AuthFailure(exception.message);
    } else if (exception is ValidationException) {
      return ValidationFailure(exception.message);
    } else if (exception is SocketException) {
      return const NetworkFailure('No internet connection. Please check your network settings.');
    } else if (exception is TimeoutException) {
      return const NetworkFailure('Request timed out. Please try again.');
    } else if (exception is FormatException) {
      return const ServerFailure('Invalid data format received from server.', 400);
    } else {
      return ServerFailure('An unexpected error occurred: ${exception.toString()}', 500);
    }
  }



  /// Show user-friendly error message
  static void showErrorToUser(BuildContext context, Failure failure) {
    String message = failure.message;
    
    // Customize message based on failure type
    if (failure is NetworkFailure) {
      if (message.contains('internet') || message.contains('connection')) {
        message = 'Please check your internet connection and try again.';
      } else if (message.contains('timeout')) {
        message = 'The request is taking too long. Please try again.';
      }
    } else if (failure is AuthFailure) {
      if (message.contains('expired') || message.contains('session')) {
        message = 'Your session has expired. Please log in again.';
        // Navigate to login screen
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }

    // Show snackbar with error message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        action: _getRetryAction(context, failure),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  static SnackBarAction? _getRetryAction(BuildContext context, Failure failure) {
    // Only show retry for network failures
    if (failure is NetworkFailure && 
        !failure.message.contains('unauthorized') && 
        !failure.message.contains('forbidden')) {
      return SnackBarAction(
        label: 'Retry',
        onPressed: () {
          // This would need to be implemented based on the specific context
          // For now, just dismiss the snackbar
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        },
      );
    }
    return null;
  }

  /// Handle errors with retry mechanism
  static Future<T> withRetry<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
    bool Function(Object)? shouldRetry,
  }) async {
    int attempts = 0;
    
    while (attempts < maxRetries) {
      try {
        return await operation();
      } catch (error) {
        attempts++;
        
        // Check if we should retry this error
        if (shouldRetry != null && !shouldRetry(error)) {
          rethrow;
        }
        
        // If this was the last attempt, rethrow the error
        if (attempts >= maxRetries) {
          Logger.error('Max retries ($maxRetries) exceeded for operation', error);
          rethrow;
        }
        
        // Log the retry attempt
        Logger.warning('Operation failed (attempt $attempts/$maxRetries), retrying in ${delay.inSeconds}s');
        
        // Wait before retrying
        await Future.delayed(delay);
        
        // Exponential backoff
        delay = Duration(milliseconds: (delay.inMilliseconds * 1.5).round());
      }
    }
    
    throw StateError('This should never be reached');
  }

  /// Check if an error is retryable
  static bool isRetryableError(Object error) {
    if (error is NetworkException) {
      // Check message content to determine if retryable
      final message = error.message.toLowerCase();
      if (message.contains('timeout') || 
          message.contains('server') || 
          message.contains('internet') ||
          message.contains('connection')) {
        return true;
      }
      if (message.contains('unauthorized') || 
          message.contains('forbidden') || 
          message.contains('bad request') ||
          message.contains('not found')) {
        return false;
      }
      return true; // Assume unknown errors might be retryable
    }
    
    if (error is SocketException || error is TimeoutException) {
      return true;
    }
    
    return false;
  }

  /// Log error with context
  static void logError(
    String message,
    Object error, {
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    Logger.error(message, error);
    
    if (stackTrace != null) {
      Logger.error('Stack trace', stackTrace);
    }
    
    if (context != null) {
      Logger.error('Error context', context);
    }
    
    // In a real app, you might want to send this to analytics
    _reportError(error, stackTrace);
  }
}

/// Extension to add error handling to Future
extension FutureErrorHandling<T> on Future<T> {
  /// Handle errors and convert to failures
  Future<T> handleErrors() async {
    try {
      return await this;
    } catch (error, stackTrace) {
      GlobalErrorHandler.logError('Future operation failed', error, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Handle errors with retry
  Future<T> withRetry({
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
  }) {
    return GlobalErrorHandler.withRetry(
      () => this,
      maxRetries: maxRetries,
      delay: delay,
      shouldRetry: GlobalErrorHandler.isRetryableError,
    );
  }
}