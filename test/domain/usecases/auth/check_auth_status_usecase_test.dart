import 'package:flutter_test/flutter_test.dart';
import 'package:mini_feed/core/errors/failures.dart';
import 'package:mini_feed/core/utils/result.dart';
import 'package:mini_feed/domain/entities/user.dart';
import 'package:mini_feed/domain/repositories/auth_repository.dart';
import 'package:mini_feed/domain/usecases/auth/check_auth_status_usecase.dart';

// Mock implementation for testing
class MockAuthRepository implements AuthRepository {
  bool isUserAuthenticated = false;
  bool shouldGetUserSucceed = true;
  bool shouldLogoutSucceed = true;
  bool shouldThrowException = false;

  @override
  Future<bool> isAuthenticated() async {
    if (shouldThrowException) {
      throw Exception('Network error');
    }
    return isUserAuthenticated;
  }

  @override
  Future<Result<User, Failure>> getCurrentUser() async {
    if (shouldThrowException) {
      throw Exception('Network error');
    }
    
    if (!shouldGetUserSucceed) {
      return Result.failure(const AuthFailure('Token expired'));
    }
    
    return Result.success(const User(
      id: 1,
      email: 'test@example.com',
      token: 'valid_token',
    ));
  }

  @override
  Future<Result<void, Failure>> logout() async {
    if (!shouldLogoutSucceed) {
      return Result.failure(const ServerFailure('Logout failed'));
    }
    isUserAuthenticated = false;
    return Result.success(null);
  }

  // Other methods not needed for this test
  @override
  Future<Result<User, Failure>> login({
    required String email,
    required String password,
  }) async => throw UnimplementedError();

  @override
  Future<Result<User, Failure>> register({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async => throw UnimplementedError();

  @override
  Future<Result<User, Failure>> refreshToken() async => throw UnimplementedError();

  @override
  Future<Result<User, Failure>> updateProfile({
    String? firstName,
    String? lastName,
    String? avatar,
  }) async => throw UnimplementedError();

  @override
  Future<Result<void, Failure>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async => throw UnimplementedError();

  @override
  Future<Result<void, Failure>> requestPasswordReset({
    required String email,
  }) async => throw UnimplementedError();

  @override
  Future<Result<void, Failure>> resetPassword({
    required String token,
    required String newPassword,
  }) async => throw UnimplementedError();

  @override
  Future<Result<void, Failure>> deleteAccount() async => throw UnimplementedError();
}

void main() {
  group('CheckAuthStatusUseCase', () {
    late CheckAuthStatusUseCase useCase;
    late MockAuthRepository mockRepository;

    setUp(() {
      mockRepository = MockAuthRepository();
      useCase = CheckAuthStatusUseCase(mockRepository);
    });

    group('user is authenticated', () {
      test('should return User when user is authenticated and user data is available', () async {
        // Arrange
        mockRepository.isUserAuthenticated = true;
        mockRepository.shouldGetUserSucceed = true;

        // Act
        final result = await useCase();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isA<User>());
        expect(result.data?.email, equals('test@example.com'));
      });

      test('should return null and logout when user is authenticated but user data is invalid', () async {
        // Arrange
        mockRepository.isUserAuthenticated = true;
        mockRepository.shouldGetUserSucceed = false;
        mockRepository.shouldLogoutSucceed = true;

        // Act
        final result = await useCase();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNull);
        expect(mockRepository.isUserAuthenticated, isFalse); // Should have logged out
      });
    });

    group('user is not authenticated', () {
      test('should return null when user is not authenticated', () async {
        // Arrange
        mockRepository.isUserAuthenticated = false;

        // Act
        final result = await useCase();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNull);
      });
    });

    group('error handling', () {
      test('should return null when isAuthenticated throws exception', () async {
        // Arrange
        mockRepository.shouldThrowException = true;

        // Act
        final result = await useCase();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNull);
      });

      test('should return null when getCurrentUser throws exception', () async {
        // Arrange
        mockRepository.isUserAuthenticated = true;
        mockRepository.shouldThrowException = true;

        // Act
        final result = await useCase();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNull);
      });

      test('should still return null even if logout fails after invalid user data', () async {
        // Arrange
        mockRepository.isUserAuthenticated = true;
        mockRepository.shouldGetUserSucceed = false;
        mockRepository.shouldLogoutSucceed = false;

        // Act
        final result = await useCase();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isNull);
      });
    });

    group('authentication flow', () {
      test('should check authentication status before getting user', () async {
        // Arrange
        var isAuthenticatedCalled = false;
        var getCurrentUserCalled = false;
        
        mockRepository.isUserAuthenticated = false;
        
        final originalIsAuthenticated = mockRepository.isAuthenticated;
        final originalGetCurrentUser = mockRepository.getCurrentUser;
        
        mockRepository.isAuthenticated = () async {
          isAuthenticatedCalled = true;
          return originalIsAuthenticated();
        };
        
        mockRepository.getCurrentUser = () async {
          getCurrentUserCalled = true;
          return originalGetCurrentUser();
        };

        // Act
        await useCase();

        // Assert
        expect(isAuthenticatedCalled, isTrue);
        expect(getCurrentUserCalled, isFalse); // Should not be called if not authenticated
      });

      test('should get current user only if authenticated', () async {
        // Arrange
        var isAuthenticatedCalled = false;
        var getCurrentUserCalled = false;
        
        mockRepository.isUserAuthenticated = true;
        mockRepository.shouldGetUserSucceed = true;
        
        final originalIsAuthenticated = mockRepository.isAuthenticated;
        final originalGetCurrentUser = mockRepository.getCurrentUser;
        
        mockRepository.isAuthenticated = () async {
          isAuthenticatedCalled = true;
          return originalIsAuthenticated();
        };
        
        mockRepository.getCurrentUser = () async {
          getCurrentUserCalled = true;
          return originalGetCurrentUser();
        };

        // Act
        await useCase();

        // Assert
        expect(isAuthenticatedCalled, isTrue);
        expect(getCurrentUserCalled, isTrue); // Should be called if authenticated
      });
    });
  });
}