import '../../../core/utils/result.dart';
import '../../../core/errors/failures.dart';
import '../../entities/user.dart';
import '../../repositories/auth_repository.dart';
import '../base_usecase.dart';

/// Use case for checking authentication status
/// 
/// Determines if the user is currently authenticated by checking
/// for a valid stored token and user data.
class CheckAuthStatusUseCase implements NoParamsUseCase<User?> {
  final AuthRepository repository;

  const CheckAuthStatusUseCase(this.repository);

  @override
  Future<Result<User?>> call() async {
    try {
      // First check if user is authenticated
      final isAuthenticatedResult = await repository.isAuthenticated();
      
      if (isAuthenticatedResult.isFailure) {
        return success(null);
      }
      
      final isAuthenticated = isAuthenticatedResult.successValue ?? false;
      
      if (!isAuthenticated) {
        return success(null);
      }

      // If authenticated, try to get current user
      final userResult = await repository.getCurrentUser();
      
      if (userResult.isSuccess) {
        return success(userResult.successValue);
      } else {
        // If we can't get user data but token exists, clear invalid session
        await repository.logout();
        return success(null);
      }
    } catch (e) {
      // If any error occurs, consider user as not authenticated
      return success(null);
    }
  }
}