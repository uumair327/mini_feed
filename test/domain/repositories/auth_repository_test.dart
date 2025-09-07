import 'package:flutter_test/flutter_test.dart';
import 'package:mini_feed/core/errors/failures.dart';
import 'package:mini_feed/core/utils/result.dart';
import 'package:mini_feed/domain/entities/user.dart';
import 'package:mini_feed/domain/repositories/auth_repository.dart';

// Mock implementation for testing the interface contract
class MockAuthRepository implements AuthRepository {
  bool _isAuthenticated = false;
  User? _currentUser;
  String? _storedToken;

  @override
  Future<Result<User>> login({
    required String email,
    required String password,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 100));

    // Mock validation
    if (email.isEmpty || password.isEmpty) {
      return Result.failure(const ValidationFailure('Email and password are required'));
    }

    if (email == 'invalid@example.com') {
      return Result.failure(const AuthFailure('Invalid credentials'));
    }

    if (email == 'network@error.com') {
      return Result.failure(const NetworkFailure('Network connection failed'));
    }

    // Mock successful login
    _currentUser = const User(
      id: 1,
      email: 'test@example.com',
      token: 'mock_token_123',
      firstName: 'Test',
      lastName: 'User',
    );
    _storedToken = 'mock_token_123';
    _isAuthenticated = true;

    return Result.success(_currentUser!);
  }

  @override
  Future<Result<void>> logout() async {
    _currentUser = null;
    _storedToken = null;
    _isAuthenticated = false;
    return Result.success(null);
  }

  @override
  Future<Result<String?>> getStoredToken() async {
    return Result.success(_storedToken);
  }

  @override
  Future<Result<bool>> isAuthenticated() async {
    return Result.success(_isAuthenticated);
  }

  @override
  Future<Result<User?>> getCurrentUser() async {
    return Result.success(_currentUser);
  }

  @override
  Future<Result<User>> refreshToken() async {
    if (!_isAuthenticated || _currentUser == null) {
      return Result.failure(const AuthFailure('No user to refresh token for'));
    }

    // Mock token refresh
    final refreshedUser = _currentUser!.copyWith(token: 'refreshed_token_456');
    _currentUser = refreshedUser;
    _storedToken = 'refreshed_token_456';

    return Result.success(refreshedUser);
  }

  @override
  Future<Result<bool>> validateToken() async {
    if (_storedToken == null) {
      return Result.success(false);
    }

    // Mock token validation
    if (_storedToken == 'invalid_token') {
      return Result.failure(const AuthFailure('Token is invalid'));
    }

    return Result.success(true);
  }
}

void main() {
  group('AuthRepository Interface Contract', () {
    late AuthRepository repository;

    setUp(() {
      repository = MockAuthRepository();
    });

    group('login', () {
      test('should return success with user when credentials are valid', () async {
        // Act
        final result = await repository.login(
          email: 'test@example.com',
          password: 'password123',
        );

        // Assert
        expect(result.isSuccess, isTrue);
        result.fold(
          (failure) => fail('Expected success but got failure: $failure'),
          (user) {
            expect(user.email, equals('test@example.com'));
            expect(user.isAuthenticated, isTrue);
          },
        );
      });

      test('should return ValidationFailure when email is empty', () async {
        // Act
        final result = await repository.login(
          email: '',
          password: 'password123',
        );

        // Assert
        expect(result.isFailure, isTrue);
        result.fold(
          (failure) => expect(failure, isA<ValidationFailure>()),
          (user) => fail('Expected failure but got success'),
        );
      });

      test('should return AuthFailure when credentials are invalid', () async {
        // Act
        final result = await repository.login(
          email: 'invalid@example.com',
          password: 'wrongpassword',
        );

        // Assert
        expect(result.isFailure, isTrue);
        result.fold(
          (failure) => expect(failure, isA<AuthFailure>()),
          (user) => fail('Expected failure but got success'),
        );
      });

      test('should return NetworkFailure when network fails', () async {
        // Act
        final result = await repository.login(
          email: 'network@error.com',
          password: 'password123',
        );

        // Assert
        expect(result.isFailure, isTrue);
        result.fold(
          (failure) => expect(failure, isA<NetworkFailure>()),
          (user) => fail('Expected failure but got success'),
        );
      });
    });

    group('logout', () {
      test('should return success and clear authentication state', () async {
        // Arrange - login first
        await repository.login(
          email: 'test@example.com',
          password: 'password123',
        );

        // Act
        final result = await repository.logout();

        // Assert
        expect(result.isSuccess, isTrue);

        // Verify authentication state is cleared
        final isAuthResult = await repository.isAuthenticated();
        expect(isAuthResult.getOrNull(), isFalse);

        final tokenResult = await repository.getStoredToken();
        expect(tokenResult.getOrNull(), isNull);
      });
    });

    group('getStoredToken', () {
      test('should return null when no token is stored', () async {
        // Act
        final result = await repository.getStoredToken();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.getOrNull(), isNull);
      });

      test('should return token when user is authenticated', () async {
        // Arrange
        await repository.login(
          email: 'test@example.com',
          password: 'password123',
        );

        // Act
        final result = await repository.getStoredToken();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.getOrNull(), isNotNull);
        expect(result.getOrNull(), equals('mock_token_123'));
      });
    });

    group('isAuthenticated', () {
      test('should return false when not authenticated', () async {
        // Act
        final result = await repository.isAuthenticated();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.getOrNull(), isFalse);
      });

      test('should return true when authenticated', () async {
        // Arrange
        await repository.login(
          email: 'test@example.com',
          password: 'password123',
        );

        // Act
        final result = await repository.isAuthenticated();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.getOrNull(), isTrue);
      });
    });

    group('getCurrentUser', () {
      test('should return null when not authenticated', () async {
        // Act
        final result = await repository.getCurrentUser();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.getOrNull(), isNull);
      });

      test('should return user when authenticated', () async {
        // Arrange
        await repository.login(
          email: 'test@example.com',
          password: 'password123',
        );

        // Act
        final result = await repository.getCurrentUser();

        // Assert
        expect(result.isSuccess, isTrue);
        final user = result.getOrNull();
        expect(user, isNotNull);
        expect(user!.email, equals('test@example.com'));
      });
    });

    group('refreshToken', () {
      test('should return AuthFailure when not authenticated', () async {
        // Act
        final result = await repository.refreshToken();

        // Assert
        expect(result.isFailure, isTrue);
        result.fold(
          (failure) => expect(failure, isA<AuthFailure>()),
          (user) => fail('Expected failure but got success'),
        );
      });

      test('should return success with updated user when authenticated', () async {
        // Arrange
        await repository.login(
          email: 'test@example.com',
          password: 'password123',
        );

        // Act
        final result = await repository.refreshToken();

        // Assert
        expect(result.isSuccess, isTrue);
        result.fold(
          (failure) => fail('Expected success but got failure: $failure'),
          (user) {
            expect(user.token, equals('refreshed_token_456'));
          },
        );
      });
    });

    group('validateToken', () {
      test('should return false when no token is stored', () async {
        // Act
        final result = await repository.validateToken();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.getOrNull(), isFalse);
      });

      test('should return true when token is valid', () async {
        // Arrange
        await repository.login(
          email: 'test@example.com',
          password: 'password123',
        );

        // Act
        final result = await repository.validateToken();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.getOrNull(), isTrue);
      });
    });
  });
}