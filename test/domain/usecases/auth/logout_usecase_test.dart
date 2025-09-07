import 'package:flutter_test/flutter_test.dart';
import 'package:mini_feed/core/errors/failures.dart';
import 'package:mini_feed/core/utils/result.dart';
import 'package:mini_feed/domain/entities/user.dart';
import 'package:mini_feed/domain/repositories/auth_repository.dart';
import 'package:mini_feed/domain/usecases/auth/logout_usecase.dart';

// Mock implementation for testing
class MockAuthRepository implements AuthRepository {
  bool shouldSucceed = true;

  @override
  Future<Result<void, Failure>> logout() async {
    if (!shouldSucceed) {
      return Result.failure(const ServerFailure('Logout failed'));
    }
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
  Future<Result<User, Failure>> getCurrentUser() async => throw UnimplementedError();

  @override
  Future<bool> isAuthenticated() async => throw UnimplementedError();

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
  group('LogoutUseCase', () {
    late LogoutUseCase useCase;
    late MockAuthRepository mockRepository;

    setUp(() {
      mockRepository = MockAuthRepository();
      useCase = LogoutUseCase(mockRepository);
    });

    test('should return success when logout is successful', () async {
      // Arrange
      mockRepository.shouldSucceed = true;

      // Act
      final result = await useCase();

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.data, isNull);
    });

    test('should return failure when repository fails', () async {
      // Arrange
      mockRepository.shouldSucceed = false;

      // Act
      final result = await useCase();

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.error, isA<ServerFailure>());
      expect(result.error?.message, equals('Logout failed'));
    });

    test('should call repository logout method', () async {
      // Arrange
      bool logoutCalled = false;
      mockRepository = MockAuthRepository();
      
      // Override the logout method to track calls
      final originalLogout = mockRepository.logout;
      mockRepository.logout = () async {
        logoutCalled = true;
        return originalLogout();
      };
      
      useCase = LogoutUseCase(mockRepository);

      // Act
      await useCase();

      // Assert
      expect(logoutCalled, isTrue);
    });
  });
}