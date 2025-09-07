import '../../../core/errors/failures.dart';
import '../../../core/utils/result.dart';
import '../../entities/user.dart';
import '../../repositories/auth_repository.dart';
import '../base_usecase.dart';

class GetCurrentUserUseCase implements NoParamsUseCase<User> {
  const GetCurrentUserUseCase(this.repository);

  final AuthRepository repository;

  @override
  Future<Result<User>> call() async {
    // Check if user is authenticated first
    final isAuthenticatedResult = await repository.isAuthenticated();
    
    if (isAuthenticatedResult.isFailure) {
      return failure(const AuthFailure('Authentication check failed'));
    }
    
    final isAuthenticated = isAuthenticatedResult.successValue ?? false;
    
    if (!isAuthenticated) {
      return failure(const AuthFailure('User is not authenticated'));
    }

    // Get current user from repository
    final userResult = await repository.getCurrentUser();
    
    if (userResult.isFailure) {
      return failure(userResult.failureValue!);
    }
    
    final user = userResult.successValue;
    if (user == null) {
      return failure(const AuthFailure('User data not found'));
    }
    
    return success(user);
  }
}

/// Use case for getting the current authenticated user
/// 
/// Retrieves the currently authenticated user's information
/// from the repository.