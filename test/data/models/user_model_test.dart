import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_feed/data/models/user_model.dart';
import 'package:mini_feed/domain/entities/user.dart';

void main() {
  group('UserModel', () {
    late UserModel userModel;
    late Map<String, dynamic> jsonMap;
    late Map<String, dynamic> reqresJsonMap;

    setUp(() {
      userModel = const UserModel(
        id: 1,
        email: 'test@example.com',
        token: 'test_token_123',
        firstName: 'Test',
        lastName: 'User',
        avatar: 'https://example.com/avatar.jpg',
      );

      jsonMap = {
        'id': 1,
        'email': 'test@example.com',
        'token': 'test_token_123',
        'first_name': 'Test',
        'last_name': 'User',
        'avatar': 'https://example.com/avatar.jpg',
      };

      reqresJsonMap = {
        'id': 1,
        'email': 'test@example.com',
        'first_name': 'Test',
        'last_name': 'User',
        'avatar': 'https://example.com/avatar.jpg',
      };
    });

    group('fromJson', () {
      test('should create UserModel from valid JSON', () {
        // Act
        final result = UserModel.fromJson(jsonMap);

        // Assert
        expect(result.id, equals(1));
        expect(result.email, equals('test@example.com'));
        expect(result.token, equals('test_token_123'));
        expect(result.firstName, equals('Test'));
        expect(result.lastName, equals('User'));
        expect(result.avatar, equals('https://example.com/avatar.jpg'));
      });

      test('should handle alternative field names (firstName/lastName)', () {
        // Arrange
        final alternativeJson = {
          'id': 1,
          'email': 'test@example.com',
          'firstName': 'Test',
          'lastName': 'User',
        };

        // Act
        final result = UserModel.fromJson(alternativeJson);

        // Assert
        expect(result.firstName, equals('Test'));
        expect(result.lastName, equals('User'));
      });

      test('should create UserModel with null optional fields', () {
        // Arrange
        final minimalJson = {
          'id': 1,
          'email': 'test@example.com',
        };

        // Act
        final result = UserModel.fromJson(minimalJson);

        // Assert
        expect(result.id, equals(1));
        expect(result.email, equals('test@example.com'));
        expect(result.token, isNull);
        expect(result.firstName, isNull);
        expect(result.lastName, isNull);
        expect(result.avatar, isNull);
      });
    });

    group('toJson', () {
      test('should convert UserModel to JSON', () {
        // Act
        final result = userModel.toJson();

        // Assert
        expect(result['id'], equals(1));
        expect(result['email'], equals('test@example.com'));
        expect(result['token'], equals('test_token_123'));
        expect(result['first_name'], equals('Test'));
        expect(result['last_name'], equals('User'));
        expect(result['avatar'], equals('https://example.com/avatar.jpg'));
      });

      test('should exclude null optional fields from JSON', () {
        // Arrange
        final userWithNulls = const UserModel(
          id: 1,
          email: 'test@example.com',
        );

        // Act
        final result = userWithNulls.toJson();

        // Assert
        expect(result.containsKey('token'), isFalse);
        expect(result.containsKey('first_name'), isFalse);
        expect(result.containsKey('last_name'), isFalse);
        expect(result.containsKey('avatar'), isFalse);
      });
    });

    group('JSON string conversion', () {
      test('should convert to and from JSON string', () {
        // Act
        final jsonString = userModel.toJsonString();
        final result = UserModel.fromJsonString(jsonString);

        // Assert
        expect(result.id, equals(userModel.id));
        expect(result.email, equals(userModel.email));
        expect(result.token, equals(userModel.token));
        expect(result.firstName, equals(userModel.firstName));
        expect(result.lastName, equals(userModel.lastName));
        expect(result.avatar, equals(userModel.avatar));
      });
    });

    group('fromDomain and toDomain', () {
      test('should convert from domain entity', () {
        // Arrange
        const domainUser = User(
          id: 2,
          email: 'domain@example.com',
          token: 'domain_token',
          firstName: 'Domain',
          lastName: 'User',
        );

        // Act
        final result = UserModel.fromDomain(domainUser);

        // Assert
        expect(result.id, equals(domainUser.id));
        expect(result.email, equals(domainUser.email));
        expect(result.token, equals(domainUser.token));
        expect(result.firstName, equals(domainUser.firstName));
        expect(result.lastName, equals(domainUser.lastName));
      });

      test('should convert to domain entity', () {
        // Act
        final result = userModel.toDomain();

        // Assert
        expect(result, isA<User>());
        expect(result.id, equals(userModel.id));
        expect(result.email, equals(userModel.email));
        expect(result.token, equals(userModel.token));
        expect(result.firstName, equals(userModel.firstName));
        expect(result.lastName, equals(userModel.lastName));
        expect(result.avatar, equals(userModel.avatar));
      });
    });

    group('reqres.in API format', () {
      test('should create UserModel from reqres JSON', () {
        // Act
        final result = UserModel.fromReqresJson(reqresJsonMap);

        // Assert
        expect(result.id, equals(1));
        expect(result.email, equals('test@example.com'));
        expect(result.firstName, equals('Test'));
        expect(result.lastName, equals('User'));
        expect(result.avatar, equals('https://example.com/avatar.jpg'));
        expect(result.token, isNull);
      });

      test('should convert to reqres JSON format', () {
        // Act
        final result = userModel.toReqresJson();

        // Assert
        expect(result['id'], equals(1));
        expect(result['email'], equals('test@example.com'));
        expect(result['first_name'], equals('Test'));
        expect(result['last_name'], equals('User'));
        expect(result['avatar'], equals('https://example.com/avatar.jpg'));
        expect(result.containsKey('token'), isFalse);
      });
    });

    group('copyWith', () {
      test('should create copy with updated fields', () {
        // Act
        final result = userModel.copyWith(
          email: 'new@example.com',
          firstName: 'New',
        );

        // Assert
        expect(result.id, equals(userModel.id));
        expect(result.email, equals('new@example.com'));
        expect(result.token, equals(userModel.token));
        expect(result.firstName, equals('New'));
        expect(result.lastName, equals(userModel.lastName));
        expect(result.avatar, equals(userModel.avatar));
      });

      test('should keep original values when no updates provided', () {
        // Act
        final result = userModel.copyWith();

        // Assert
        expect(result.id, equals(userModel.id));
        expect(result.email, equals(userModel.email));
        expect(result.token, equals(userModel.token));
        expect(result.firstName, equals(userModel.firstName));
        expect(result.lastName, equals(userModel.lastName));
        expect(result.avatar, equals(userModel.avatar));
      });
    });

    group('copyWithoutToken', () {
      test('should create copy without token', () {
        // Act
        final result = userModel.copyWithoutToken();

        // Assert
        expect(result.id, equals(userModel.id));
        expect(result.email, equals(userModel.email));
        expect(result.token, isNull);
        expect(result.firstName, equals(userModel.firstName));
        expect(result.lastName, equals(userModel.lastName));
        expect(result.avatar, equals(userModel.avatar));
        expect(result.isAuthenticated, isFalse);
      });
    });

    group('mock factory', () {
      test('should create mock user with default values', () {
        // Act
        final result = UserModel.mock();

        // Assert
        expect(result.id, equals(1));
        expect(result.email, equals('test@example.com'));
        expect(result.firstName, equals('Test'));
        expect(result.lastName, equals('User'));
        expect(result.token, isNull);
      });

      test('should create mock user with custom values', () {
        // Act
        final result = UserModel.mock(
          id: 99,
          email: 'custom@example.com',
          token: 'custom_token',
        );

        // Assert
        expect(result.id, equals(99));
        expect(result.email, equals('custom@example.com'));
        expect(result.token, equals('custom_token'));
        expect(result.isAuthenticated, isTrue);
      });
    });

    group('inherited properties', () {
      test('should inherit fullName property from User entity', () {
        // Act
        final fullName = userModel.fullName;

        // Assert
        expect(fullName, equals('Test User'));
      });

      test('should inherit isAuthenticated property from User entity', () {
        // Act
        final isAuthenticated = userModel.isAuthenticated;

        // Assert
        expect(isAuthenticated, isTrue);
      });

      test('should return false for isAuthenticated when token is null', () {
        // Arrange
        final userWithoutToken = userModel.copyWithoutToken();

        // Act
        final isAuthenticated = userWithoutToken.isAuthenticated;

        // Assert
        expect(isAuthenticated, isFalse);
      });
    });

    group('toString', () {
      test('should return meaningful string representation', () {
        // Act
        final result = userModel.toString();

        // Assert
        expect(result, contains('UserModel'));
        expect(result, contains('test@example.com'));
        expect(result, contains('Test User'));
        expect(result, contains('true')); // isAuthenticated
      });
    });
  });
}