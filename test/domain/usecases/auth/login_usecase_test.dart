import 'package:flutter_test/flutter_test.dart';
import 'package:mini_feed/core/errors/failures.dart';
import 'package:mini_feed/core/utils/result.dart';
import 'package:mini_feed/domain/entities/user.dart';
import 'package:mini_feed/domain/repositories/auth_repository.dart';
import 'package:mini_feed/domain/usecases/auth/login_usecase.dart';

// Mock implementation for testing
class MockAuthRepository implements AuthRepository {
  bool shouldSucceed = true;
  String? expectedEmail;
  String? expectedPassword;

  @override
  Future<Result<User, Failure>> login({
    required String email,
    required String password,
  }) async {
    if (!shouldSucceed) {
      return Result.failure(const AuthFailure('Invalid credentials'));
    }

    if (expectedEmail != null && email != expectedEmail) {
      return Result.failure(const AuthFailure('Invalid email'));
    }

    if (expectedPassword != null && password != expectedPassword) {
      return Result.failure(const AuthFailure('Invalid password'));
    }

    return Result.success(const User(
      id: 1,
      email: 'test@example.com',
      token: 'mock_token',
    ));
  }

  // Other methods not needed for this test
  @override
  Future<Result<User, Failure>> register({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async => throw UnimplementedError();

  @override
  Future<Result<void, Failure>> logout() async => throw UnimplementedError();

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
  group('LoginUseCase', () {
    late LoginUseCase useCase;
    late MockAuthRepository mockRepository;

    setUp(() {
      mockRepository = MockAuthRepository();
      useCase = LoginUseCase(mockRepository);
    });

    group('successful login', () {
      test('should return User when login is successful', () async {
        // Arrange
        mockRepository.shouldSucceed = true;
        const params = LoginParams(
          email: 'test@example.com',
          password: 'password123',
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isA<User>());
        expect(result.data?.email, equals('test@example.com'));
      });
    });

    group('validation errors', () {
      test('should return ValidationFailure when email is empty', () async {
        // Arrange
        const params = LoginParams(
          email: '',
          password: 'password123',
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.error, isA<ValidationFailure>());
        expect(result.error?.message, equals('Email is required'));
      });

      test('should return ValidationFailure when password is empty', () async {
        // Arrange
        const params = LoginParams(
          email: 'test@example.com',
          password: '',
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.error, isA<ValidationFailure>());
        expect(result.error?.message, equals('Password is required'));
      });

      test('should return ValidationFailure when email format is invalid', () async {
        // Arrange
        const params = LoginParams(
          email: 'invalid-email',
          password: 'password123',
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.error, isA<ValidationFailure>());
        expect(result.error?.message, equals('Please enter a valid email address'));
      });

      test('should return ValidationFailure when password is too short', () async {
        // Arrange
        const params = LoginParams(
          email: 'test@example.com',
          password: '123',
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.error, isA<ValidationFailure>());
        expect(result.error?.message, equals('Password must be at least 6 characters'));
      });
    });

    group('authentication errors', () {
      test('should return AuthFailure when repository fails', () async {
        // Arrange
        mockRepository.shouldSucceed = false;
        const params = LoginParams(
          email: 'test@example.com',
          password: 'password123',
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.error, isA<AuthFailure>());
      });
    });

    group('email validation', () {
      test('should accept valid email formats', () async {
        // Arrange
        mockRepository.shouldSucceed = true;
        const validEmails = [
          'test@example.com',
          'user.name@domain.co.uk',
          'user+tag@example.org',
        ];

        for (final email in validEmails) {
          final params = LoginParams(
            email: email,
            password: 'password123',
          );

          // Act
          final result = await useCase(params);

          // Assert
          expect(result.isSuccess, isTrue, reason: 'Failed for email: $email');
        }
      });

      test('should reject invalid email formats', () async {
        // Arrange
        const invalidEmails = [
          'invalid-email',
          '@example.com',
          'test@',
          'test.example.com',
          '',
        ];

        for (final email in invalidEmails) {
          final params = LoginParams(
            email: email,
            password: 'password123',
          );

          // Act
          final result = await useCase(params);

          // Assert
          expect(result.isFailure, isTrue, reason: 'Should fail for email: $email');
          expect(result.error, isA<ValidationFailure>());
        }
      });
    });
  });

  group('LoginParams', () {
    test('should have correct equality and hashCode', () {
      // Arrange
      const params1 = LoginParams(email: 'test@example.com', password: 'password');
      const params2 = LoginParams(email: 'test@example.com', password: 'password');
      const params3 = LoginParams(email: 'different@example.com', password: 'password');

      // Assert
      expect(params1, equals(params2));
      expect(params1.hashCode, equals(params2.hashCode));
      expect(params1, isNot(equals(params3)));
      expect(params1.hashCode, isNot(equals(params3.hashCode)));
    });

    test('should hide password in toString', () {
      // Arrange
      const params = LoginParams(email: 'test@example.com', password: 'secret');

      // Act
      final string = params.toString();

      // Assert
      expect(string, contains('test@example.com'));
      expect(string, contains('[HIDDEN]'));
      expect(string, isNot(contains('secret')));
    });
  });
}