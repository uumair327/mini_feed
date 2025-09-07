import 'dart:developer' as developer;

/// Utility class for logging throughout the application
class Logger {
  static const String _tag = 'MiniFeed';
  
  /// Log debug messages (only in debug mode)
  static void debug(String message, [String? tag]) {
    developer.log(
      message,
      name: tag ?? _tag,
      level: 500, // Debug level
    );
  }
  
  /// Log info messages
  static void info(String message, [String? tag]) {
    developer.log(
      message,
      name: tag ?? _tag,
      level: 800, // Info level
    );
  }
  
  /// Log warning messages
  static void warning(String message, [String? tag]) {
    developer.log(
      message,
      name: tag ?? _tag,
      level: 900, // Warning level
    );
  }
  
  /// Log error messages
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    developer.log(
      message,
      name: _tag,
      level: 1000, // Error level
      error: error,
      stackTrace: stackTrace,
    );
  }
  
  /// Log network requests
  static void network(String method, String url, [Map<String, dynamic>? data]) {
    debug('$method $url ${data != null ? '- Data: $data' : ''}', 'Network');
  }
  
  /// Log cache operations
  static void cache(String operation, String key, [String? details]) {
    debug('Cache $operation: $key ${details ?? ''}', 'Cache');
  }
  
  /// Log BLoC events and states
  static void bloc(String blocName, String event, [String? state]) {
    debug(
      '$blocName - Event: $event ${state != null ? '-> State: $state' : ''}',
      'BLoC',
    );
  }
}
