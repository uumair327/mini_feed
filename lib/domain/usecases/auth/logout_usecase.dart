import '../../../core/utils/result.dart';
import '../../../core/errors/failures.dart';
import '../../repositories/auth_repository.dart';
import '../base_usecase.dart';

/// Use case for user logout
/// 
/// Handles the logout process by clearing authentication data
/// and invalidating the user session.
class LogoutUseCase implements NoParamsUseCase<void> {
  final AuthRepository repository;

  const LogoutUseCase(this.repository);

  @override
  Future<Result<void>> call() async {
    // Delegate to repository for logout
    return await repository.logout();
  }
}