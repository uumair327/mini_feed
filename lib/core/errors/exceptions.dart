/// Base exception class for all custom exceptions
abstract class AppException implements Exception {
  const AppException(this.message);
  
  final String message;
  
  @override
  String toString() => 'AppException: $message';
}

/// Exception thrown when network operations fail
class NetworkException extends AppException {
  const NetworkException(super.message);
  
  @override
  String toString() => 'NetworkException: $message';
}

/// Exception thrown when cache operations fail
class CacheException extends AppException {
  const CacheException(super.message);
  
  @override
  String toString() => 'CacheException: $message';
}

/// Exception thrown when authentication operations fail
class AuthException extends AppException {
  const AuthException(super.message);
  
  @override
  String toString() => 'AuthException: $message';
}

/// Exception thrown when server returns an error response
class ServerException extends AppException {
  const ServerException(super.message, this.statusCode);
  
  final int statusCode;
  
  @override
  String toString() => 'ServerException: $message (Status: $statusCode)';
}

/// Exception thrown when data parsing fails
class ParsingException extends AppException {
  const ParsingException(super.message);
  
  @override
  String toString() => 'ParsingException: $message';
}

/// Exception thrown when validation fails
class ValidationException extends AppException {
  const ValidationException(super.message);
  
  @override
  String toString() => 'ValidationException: $message';
}
