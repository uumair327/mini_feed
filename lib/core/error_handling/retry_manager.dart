import 'dart:async';
import 'dart:math';

import '../utils/logger.dart';

/// Configuration for retry behavior
class RetryConfig {
  final int maxAttempts;
  final Duration initialDelay;
  final Duration maxDelay;
  final double backoffMultiplier;
  final bool useJitter;
  final bool Function(Object error)? shouldRetry;

  const RetryConfig({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 30),
    this.backoffMultiplier = 2.0,
    this.useJitter = true,
    this.shouldRetry,
  });

  /// Default retry config for network operations
  static const network = RetryConfig(
    maxAttempts: 3,
    initialDelay: Duration(seconds: 1),
    maxDelay: Duration(seconds: 10),
    backoffMultiplier: 2.0,
    useJitter: true,
  );

  /// Aggressive retry config for critical operations
  static const aggressive = RetryConfig(
    maxAttempts: 5,
    initialDelay: Duration(milliseconds: 500),
    maxDelay: Duration(seconds: 30),
    backoffMultiplier: 1.5,
    useJitter: true,
  );

  /// Conservative retry config for non-critical operations
  static const conservative = RetryConfig(
    maxAttempts: 2,
    initialDelay: Duration(seconds: 2),
    maxDelay: Duration(seconds: 15),
    backoffMultiplier: 2.0,
    useJitter: false,
  );
}

/// Result of a retry operation
class RetryResult<T> {
  final T? value;
  final Object? error;
  final int attempts;
  final Duration totalDuration;
  final bool succeeded;

  const RetryResult._({
    this.value,
    this.error,
    required this.attempts,
    required this.totalDuration,
    required this.succeeded,
  });

  factory RetryResult.success(T value, int attempts, Duration totalDuration) {
    return RetryResult._(
      value: value,
      attempts: attempts,
      totalDuration: totalDuration,
      succeeded: true,
    );
  }

  factory RetryResult.failure(Object error, int attempts, Duration totalDuration) {
    return RetryResult._(
      error: error,
      attempts: attempts,
      totalDuration: totalDuration,
      succeeded: false,
    );
  }
}

/// Manager for handling retry logic
class RetryManager {
  static final Random _random = Random();

  /// Execute an operation with retry logic
  static Future<T> execute<T>(
    Future<T> Function() operation, {
    RetryConfig config = RetryConfig.network,
    String? operationName,
  }) async {
    final stopwatch = Stopwatch()..start();
    int attempts = 0;
    Object? lastError;

    while (attempts < config.maxAttempts) {
      attempts++;
      
      try {
        final result = await operation();
        stopwatch.stop();
        
        if (attempts > 1) {
          Logger.info(
            'Operation ${operationName ?? 'unknown'} succeeded on attempt $attempts '
            'after ${stopwatch.elapsedMilliseconds}ms'
          );
        }
        
        return result;
      } catch (error) {
        lastError = error;
        
        // Check if we should retry this error
        if (config.shouldRetry != null && !config.shouldRetry!(error)) {
          Logger.warning(
            'Operation ${operationName ?? 'unknown'} failed with non-retryable error: $error'
          );
          rethrow;
        }
        
        // If this was the last attempt, rethrow the error
        if (attempts >= config.maxAttempts) {
          stopwatch.stop();
          Logger.error(
            'Operation ${operationName ?? 'unknown'} failed after $attempts attempts '
            'in ${stopwatch.elapsedMilliseconds}ms',
            error,
          );
          rethrow;
        }
        
        // Calculate delay for next attempt
        final delay = _calculateDelay(attempts, config);
        
        Logger.warning(
          'Operation ${operationName ?? 'unknown'} failed on attempt $attempts, '
          'retrying in ${delay.inMilliseconds}ms: $error'
        );
        
        // Wait before retrying
        await Future.delayed(delay);
      }
    }
    
    // This should never be reached, but just in case
    throw lastError ?? StateError('Retry loop completed without result');
  }

  /// Execute an operation with retry and return detailed result
  static Future<RetryResult<T>> executeWithResult<T>(
    Future<T> Function() operation, {
    RetryConfig config = RetryConfig.network,
    String? operationName,
  }) async {
    final stopwatch = Stopwatch()..start();
    int attempts = 0;
    Object? lastError;

    while (attempts < config.maxAttempts) {
      attempts++;
      
      try {
        final result = await operation();
        stopwatch.stop();
        
        return RetryResult.success(result, attempts, stopwatch.elapsed);
      } catch (error) {
        lastError = error;
        
        // Check if we should retry this error
        if (config.shouldRetry != null && !config.shouldRetry!(error)) {
          stopwatch.stop();
          return RetryResult.failure(error, attempts, stopwatch.elapsed);
        }
        
        // If this was the last attempt, return failure
        if (attempts >= config.maxAttempts) {
          stopwatch.stop();
          return RetryResult.failure(error, attempts, stopwatch.elapsed);
        }
        
        // Calculate delay for next attempt
        final delay = _calculateDelay(attempts, config);
        
        // Wait before retrying
        await Future.delayed(delay);
      }
    }
    
    // This should never be reached
    stopwatch.stop();
    return RetryResult.failure(
      lastError ?? StateError('Retry loop completed without result'),
      attempts,
      stopwatch.elapsed,
    );
  }

  /// Calculate delay for the next retry attempt
  static Duration _calculateDelay(int attempt, RetryConfig config) {
    // Calculate exponential backoff
    final baseDelay = config.initialDelay.inMilliseconds;
    final exponentialDelay = baseDelay * pow(config.backoffMultiplier, attempt - 1);
    
    // Apply maximum delay limit
    final clampedDelay = min(exponentialDelay, config.maxDelay.inMilliseconds.toDouble());
    
    // Add jitter if enabled
    final finalDelay = config.useJitter 
        ? _addJitter(clampedDelay.toInt())
        : clampedDelay.toInt();
    
    return Duration(milliseconds: finalDelay);
  }

  /// Add random jitter to delay to avoid thundering herd problem
  static int _addJitter(int delayMs) {
    // Add up to 25% random jitter
    final jitterRange = (delayMs * 0.25).toInt();
    final jitter = _random.nextInt(jitterRange + 1);
    return delayMs + jitter;
  }

  /// Check if an error is retryable based on common patterns
  static bool isRetryableError(Object error) {
    final errorString = error.toString().toLowerCase();
    
    // Network-related errors that are typically retryable
    if (errorString.contains('timeout') ||
        errorString.contains('connection') ||
        errorString.contains('network') ||
        errorString.contains('socket') ||
        errorString.contains('host') ||
        errorString.contains('dns')) {
      return true;
    }
    
    // HTTP status codes that are retryable
    if (errorString.contains('500') || // Internal Server Error
        errorString.contains('502') || // Bad Gateway
        errorString.contains('503') || // Service Unavailable
        errorString.contains('504') || // Gateway Timeout
        errorString.contains('429')) { // Too Many Requests
      return true;
    }
    
    // Non-retryable errors
    if (errorString.contains('400') || // Bad Request
        errorString.contains('401') || // Unauthorized
        errorString.contains('403') || // Forbidden
        errorString.contains('404') || // Not Found
        errorString.contains('422')) { // Unprocessable Entity
      return false;
    }
    
    // Default to retryable for unknown errors
    return true;
  }
}

/// Extension to add retry functionality to Future
extension RetryExtension<T> on Future<T> {
  /// Add retry logic to any Future
  Future<T> retry({
    RetryConfig config = RetryConfig.network,
    String? operationName,
  }) {
    return RetryManager.execute(
      () => this,
      config: config,
      operationName: operationName,
    );
  }

  /// Add retry logic and get detailed result
  Future<RetryResult<T>> retryWithResult({
    RetryConfig config = RetryConfig.network,
    String? operationName,
  }) {
    return RetryManager.executeWithResult(
      () => this,
      config: config,
      operationName: operationName,
    );
  }
}

/// Circuit breaker for preventing cascading failures
class CircuitBreaker {
  final String name;
  final int failureThreshold;
  final Duration timeout;
  final Duration resetTimeout;

  int _failureCount = 0;
  DateTime? _lastFailureTime;
  CircuitBreakerState _state = CircuitBreakerState.closed;

  CircuitBreaker({
    required this.name,
    this.failureThreshold = 5,
    this.timeout = const Duration(seconds: 30),
    this.resetTimeout = const Duration(minutes: 1),
  });

  CircuitBreakerState get state => _state;
  int get failureCount => _failureCount;

  /// Execute an operation through the circuit breaker
  Future<T> execute<T>(Future<T> Function() operation) async {
    if (_state == CircuitBreakerState.open) {
      if (_shouldAttemptReset()) {
        _state = CircuitBreakerState.halfOpen;
        Logger.info('Circuit breaker $name transitioning to half-open');
      } else {
        throw CircuitBreakerOpenException('Circuit breaker $name is open');
      }
    }

    try {
      final result = await operation().timeout(timeout);
      _onSuccess();
      return result;
    } catch (error) {
      _onFailure();
      rethrow;
    }
  }

  bool _shouldAttemptReset() {
    if (_lastFailureTime == null) return false;
    return DateTime.now().difference(_lastFailureTime!) > resetTimeout;
  }

  void _onSuccess() {
    _failureCount = 0;
    _state = CircuitBreakerState.closed;
    if (_state != CircuitBreakerState.closed) {
      Logger.info('Circuit breaker $name reset to closed');
    }
  }

  void _onFailure() {
    _failureCount++;
    _lastFailureTime = DateTime.now();

    if (_failureCount >= failureThreshold) {
      _state = CircuitBreakerState.open;
      Logger.warning('Circuit breaker $name opened after $failureCount failures');
    }
  }

  /// Reset the circuit breaker manually
  void reset() {
    _failureCount = 0;
    _lastFailureTime = null;
    _state = CircuitBreakerState.closed;
    Logger.info('Circuit breaker $name manually reset');
  }
}

enum CircuitBreakerState { closed, open, halfOpen }

class CircuitBreakerOpenException implements Exception {
  final String message;
  const CircuitBreakerOpenException(this.message);
  
  @override
  String toString() => 'CircuitBreakerOpenException: $message';
}