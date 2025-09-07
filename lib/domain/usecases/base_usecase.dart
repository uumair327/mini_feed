import '../../core/utils/result.dart';
import '../../core/errors/failures.dart';

/// Base class for all use cases
/// 
/// Use cases represent the business logic of the application and are the entry
/// points for the presentation layer to interact with the domain layer.
/// 
/// Type parameters:
/// - [Type]: The return type of the use case
/// - [Params]: The parameters required by the use case
abstract class UseCase<Type, Params> {
  /// Execute the use case with the given parameters
  /// 
  /// Returns a [Result] containing either the success data of type [Type]
  /// or a [Failure] if the operation fails.
  Future<Result<Type>> call(Params params);
}

/// Use case that doesn't require any parameters
abstract class NoParamsUseCase<Type> {
  /// Execute the use case without parameters
  /// 
  /// Returns a [Result] containing either the success data of type [Type]
  /// or a [Failure] if the operation fails.
  Future<Result<Type>> call();
}

/// Parameters class for use cases that don't need parameters
class NoParams {
  const NoParams();
}