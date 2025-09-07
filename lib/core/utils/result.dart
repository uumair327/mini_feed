import 'package:dartz/dartz.dart';

import '../errors/failures.dart';

/// Type alias for Either&lt;Failure, T&gt; to represent operation results
typedef Result<T> = Either<Failure, T>;

/// Extension methods for Result type
extension ResultExtension<T> on Result<T> {
  /// Returns true if the result is a success (Right)
  bool get isSuccess => isRight();
  
  /// Returns true if the result is a failure (Left)
  bool get isFailure => isLeft();
  
  /// Gets the success value or null if it's a failure
  T? get successValue => fold(
    (failure) => null,
    (success) => success,
  );
  
  /// Gets the failure or null if it's a success
  Failure? get failureValue => fold(
    (failure) => failure,
    (success) => null,
  );
}
