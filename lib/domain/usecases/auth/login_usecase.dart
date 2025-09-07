import '../../../core/utils/result.dart';
import '../../../core/errors/failures.dart';
import '../../entities/user.dart';
import '../../repositories/auth_repository.dart';
import '../base_usecase.dart';

/// Use case for user authentication
/// 
/// Handles the login process by validating credentials and authenticating
/// the user through the AuthRepository.
class LoginUseCase implements UseCase<User, LoginParams> {
  final AuthRepository repository;

  const LoginUseCase(this.repository);

  @override
  Future<Result<User>> call(LoginParams params) async {
    // Validate input parameters
    if (params.email.isEmpty) {
      return failure(const ValidationFailure('Email is required'));
    }
    
    if (params.password.isEmpty) {
      return failure(const ValidationFailure('Password is required'));
    }
    
    if (!_isValidEmail(params.email)) {
      return failure(const ValidationFailure('Please enter a valid email address'));
    }
    
    if (params.password.length < 6) {
      return failure(const ValidationFailure('Password must be at least 6 characters'));
    }

    // Delegate to repository for authentication
    return await repository.login(
      email: params.email,
      password: params.password,
    );
  }

  /// Validates email format using a simple regex
  bool _isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }
}

/// Parameters for the login use case
class LoginParams {
  final String email;
  final String password;

  const LoginParams({
    required this.email,
    required this.password,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LoginParams &&
        other.email == email &&
        other.password == password;
  }

  @override
  int get hashCode => email.hashCode ^ password.hashCode;

  @override
  String toString() => 'LoginParams(email: $email, password: [HIDDEN])';
}