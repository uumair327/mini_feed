import 'package:equatable/equatable.dart';

/// Base failure class for error handling in the domain layer
abstract class Failure extends Equatable {
  const Failure(this.message);
  
  final String message;
  
  @override
  List<Object> get props => [message];
}

/// Failure when network operations fail
class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

/// Failure when cache operations fail
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

/// Failure when authentication operations fail
class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

/// Failure when server returns an error response
class ServerFailure extends Failure {
  const ServerFailure(super.message, this.statusCode);
  
  final int statusCode;
  
  @override
  List<Object> get props => [message, statusCode];
}

/// Failure when data parsing fails
class ParsingFailure extends Failure {
  const ParsingFailure(super.message);
}

/// Failure when validation fails
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// Failure when unexpected errors occur
class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.message);
}
