import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_feed/data/models/login_response_model.dart';
import 'package:mini_feed/data/models/user_model.dart';

void main() {
  group('LoginResponseModel', () {
    late LoginResponseModel loginResponse;
    late UserModel user;
    late Map<String, dynamic> jsonMap;

    setUp(() {
      user = const UserModel(
        id: 1,
        email: 'test@example.com',
        firstName: 'Test',
        lastName: 'User',
        avatar: 'https://example.com/avatar.jpg',
      );

      loginResponse = LoginResponseModel(
        user: user,
        token: 'test_token_123',
        refreshToken: 'refresh_token_456',
        expiresIn: 3600,
        tokenType: 'Bearer',
      );

      jsonMap = {
        'user': {
          'id': 1,
          'email': 'test@example.com',
          'first_name': 'Test',
          'last_name': 'User',
          'avatar': 'https://example.com/avatar.jpg',
        },
        'token': 'test_token_123',
        'refresh_token': 'refresh_token_456',
        'expires_in': 3600,
        'token_type': 'Bearer',
      };
    });

    group('fromJson', () {
      test('should create LoginResponseModel from valid JSON', () {
        // Act
        final result = LoginResponseModel.fromJson(jsonMap);

        // Assert
        expect(result.user.id, equals(1));
        expect(result.user.email, equals('test@example.com'));
        expect(result.token, equals('test_token_123'));
        expect(result.refreshToken, equals('refresh_token_456'));
        expect(result.expiresIn, equals(3600));
        expect(result.tokenType, equals('Bearer'));
      });

      test('should create LoginResponseModel with default token type when not provided', () {
        // Arrange
        final jsonWithoutTokenType = Map<String, dynamic>.from(jsonMap);
        jsonWithoutTokenType.remove('token_type');

        // Act
        final result = LoginResponseModel.fromJson(jsonWithoutTokenType);

        // Assert
        expect(result.tokenType, equals('Bearer'));
      });

      test('should create LoginResponseModel with null optional fields', () {
        // Arrange
        final minimalJson = {
          'user': {
            'id': 1,
            'email': 'test@example.com',
          },
          'token': 'test_token_123',
        };

        // Act
        final result = LoginResponseModel.fromJson(minimalJson);

        // Assert
        expect(result.user.id, equals(1));
        expect(result.user.email, equals('test@example.com'));
        expect(result.token, equals('test_token_123'));
        expect(result.refreshToken, isNull);
        expect(result.expiresIn, isNull);
        expect(result.tokenType, equals('Bearer'));
      });
    });

    group('toJson', () {
      test('should convert LoginResponseModel to JSON', () {
        // Act
        final result = loginResponse.toJson();

        // Assert
        expect(result['user'], isA<Map<String, dynamic>>());
        expect(result['token'], equals('test_token_123'));
        expect(result['refresh_token'], equals('refresh_token_456'));
        expect(result['expires_in'], equals(3600));
        expect(result['token_type'], equals('Bearer'));
      });

      test('should exclude null optional fields from JSON', () {
        // Arrange
        final loginResponseWithNulls = LoginResponseModel(
          user: user,
          token: 'test_token_123',
          refreshToken: null,
          expiresIn: null,
        );

        // Act
        final result = loginResponseWithNulls.toJson();

        // Assert
        expect(result.containsKey('refresh_token'), isFalse);
        expect(result.containsKey('expires_in'), isFalse);
        expect(result['token_type'], equals('Bearer'));
      });
    });

    group('JSON string conversion', () {
      test('should convert to and from JSON string', () {
        // Act
        final jsonString = loginResponse.toJsonString();
        final result = LoginResponseModel.fromJsonString(jsonString);

        // Assert
        expect(result.user.email, equals(loginResponse.user.email));
        expect(result.token, equals(loginResponse.token));
        expect(result.refreshToken, equals(loginResponse.refreshToken));
        expect(result.expiresIn, equals(loginResponse.expiresIn));
        expect(result.tokenType, equals(loginResponse.tokenType));
      });
    });

    group('toDomain', () {
      test('should convert to domain User entity with token', () {
        // Act
        final result = loginResponse.toDomain();

        // Assert
        expect(result.id, equals(user.id));
        expect(result.email, equals(user.email));
        expect(result.token, equals(loginResponse.token));
        expect(result.firstName, equals(user.firstName));
        expect(result.lastName, equals(user.lastName));
        expect(result.avatar, equals(user.avatar));
        expect(result.isAuthenticated, isTrue);
      });
    });

    group('copyWith', () {
      test('should create copy with updated fields', () {
        // Act
        final result = loginResponse.copyWith(
          token: 'new_token',
          expiresIn: 7200,
        );

        // Assert
        expect(result.user, equals(loginResponse.user));
        expect(result.token, equals('new_token'));
        expect(result.refreshToken, equals(loginResponse.refreshToken));
        expect(result.expiresIn, equals(7200));
        expect(result.tokenType, equals(loginResponse.tokenType));
      });

      test('should keep original values when no updates provided', () {
        // Act
        final result = loginResponse.copyWith();

        // Assert
        expect(result.user, equals(loginResponse.user));
        expect(result.token, equals(loginResponse.token));
        expect(result.refreshToken, equals(loginResponse.refreshToken));
        expect(result.expiresIn, equals(loginResponse.expiresIn));
        expect(result.tokenType, equals(loginResponse.tokenType));
      });
    });

    group('authorizationHeader', () {
      test('should return properly formatted authorization header', () {
        // Act
        final result = loginResponse.authorizationHeader;

        // Assert
        expect(result, equals('Bearer test_token_123'));
      });

      test('should work with custom token type', () {
        // Arrange
        final customLoginResponse = loginResponse.copyWith(tokenType: 'Custom');

        // Act
        final result = customLoginResponse.authorizationHeader;

        // Assert
        expect(result, equals('Custom test_token_123'));
      });
    });

    group('equality and hashCode', () {
      test('should be equal when all properties are the same', () {
        // Arrange
        final other = LoginResponseModel(
          user: user,
          token: 'test_token_123',
          refreshToken: 'refresh_token_456',
          expiresIn: 3600,
          tokenType: 'Bearer',
        );

        // Assert
        expect(loginResponse, equals(other));
        expect(loginResponse.hashCode, equals(other.hashCode));
      });

      test('should not be equal when properties differ', () {
        // Arrange
        final other = loginResponse.copyWith(token: 'different_token');

        // Assert
        expect(loginResponse, isNot(equals(other)));
        expect(loginResponse.hashCode, isNot(equals(other.hashCode)));
      });
    });

    group('toString', () {
      test('should return meaningful string representation', () {
        // Act
        final result = loginResponse.toString();

        // Assert
        expect(result, contains('LoginResponseModel'));
        expect(result, contains('test@example.com'));
        expect(result, contains('Bearer'));
        expect(result, contains('3600'));
      });
    });
  });
}