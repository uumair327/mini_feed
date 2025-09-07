import 'package:flutter_test/flutter_test.dart';
import 'package:mini_feed/domain/entities/user.dart';

void main() {
  group('User Entity', () {
    const testUser = User(
      id: 1,
      email: 'test@example.com',
      token: 'test_token_123',
      firstName: 'John',
      lastName: 'Doe',
      avatar: 'https://example.com/avatar.jpg',
    );

    test('should create user with required fields', () {
      // Arrange & Act
      const user = User(
        id: 1,
        email: 'test@example.com',
      );

      // Assert
      expect(user.id, equals(1));
      expect(user.email, equals('test@example.com'));
      expect(user.token, isNull);
      expect(user.firstName, isNull);
      expect(user.lastName, isNull);
      expect(user.avatar, isNull);
    });

    test('should return correct full name when both names provided', () {
      // Act
      final fullName = testUser.fullName;

      // Assert
      expect(fullName, equals('John Doe'));
    });

    test('should return first name when only first name provided', () {
      // Arrange
      const user = User(
        id: 1,
        email: 'test@example.com',
        firstName: 'John',
      );

      // Act
      final fullName = user.fullName;

      // Assert
      expect(fullName, equals('John'));
    });

    test('should return last name when only last name provided', () {
      // Arrange
      const user = User(
        id: 1,
        email: 'test@example.com',
        lastName: 'Doe',
      );

      // Act
      final fullName = user.fullName;

      // Assert
      expect(fullName, equals('Doe'));
    });

    test('should return email when no names provided', () {
      // Arrange
      const user = User(
        id: 1,
        email: 'test@example.com',
      );

      // Act
      final fullName = user.fullName;

      // Assert
      expect(fullName, equals('test@example.com'));
    });

    test('should return true for isAuthenticated when token exists', () {
      // Act & Assert
      expect(testUser.isAuthenticated, isTrue);
    });

    test('should return false for isAuthenticated when token is null', () {
      // Arrange
      const user = User(
        id: 1,
        email: 'test@example.com',
      );

      // Act & Assert
      expect(user.isAuthenticated, isFalse);
    });

    test('should return false for isAuthenticated when token is empty', () {
      // Arrange
      const user = User(
        id: 1,
        email: 'test@example.com',
        token: '',
      );

      // Act & Assert
      expect(user.isAuthenticated, isFalse);
    });

    test('should create copy with updated fields', () {
      // Act
      final updatedUser = testUser.copyWith(
        email: 'updated@example.com',
        firstName: 'Jane',
      );

      // Assert
      expect(updatedUser.id, equals(testUser.id));
      expect(updatedUser.email, equals('updated@example.com'));
      expect(updatedUser.token, equals(testUser.token));
      expect(updatedUser.firstName, equals('Jane'));
      expect(updatedUser.lastName, equals(testUser.lastName));
      expect(updatedUser.avatar, equals(testUser.avatar));
    });

    test('should create copy without token', () {
      // Act
      final loggedOutUser = testUser.copyWithoutToken();

      // Assert
      expect(loggedOutUser.id, equals(testUser.id));
      expect(loggedOutUser.email, equals(testUser.email));
      expect(loggedOutUser.token, isNull);
      expect(loggedOutUser.firstName, equals(testUser.firstName));
      expect(loggedOutUser.lastName, equals(testUser.lastName));
      expect(loggedOutUser.avatar, equals(testUser.avatar));
      expect(loggedOutUser.isAuthenticated, isFalse);
    });

    test('should support equality comparison', () {
      // Arrange
      const user1 = User(
        id: 1,
        email: 'test@example.com',
        token: 'token',
      );
      const user2 = User(
        id: 1,
        email: 'test@example.com',
        token: 'token',
      );
      const user3 = User(
        id: 2,
        email: 'test@example.com',
        token: 'token',
      );

      // Act & Assert
      expect(user1, equals(user2));
      expect(user1, isNot(equals(user3)));
    });

    test('should have proper toString representation', () {
      // Act
      final stringRepresentation = testUser.toString();

      // Assert
      expect(stringRepresentation, contains('User('));
      expect(stringRepresentation, contains('id: 1'));
      expect(stringRepresentation, contains('email: test@example.com'));
      expect(stringRepresentation, contains('fullName: John Doe'));
      expect(stringRepresentation, contains('isAuthenticated: true'));
    });
  });
}