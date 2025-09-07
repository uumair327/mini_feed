import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mini_feed/core/storage/storage_service.dart';
import 'package:mini_feed/core/storage/token_storage.dart';
import 'package:mini_feed/core/utils/result.dart';
import 'package:mini_feed/core/errors/exceptions.dart';
import 'package:mini_feed/data/datasources/local/auth_local_datasource.dart';
import 'package:mini_feed/data/models/login_response_model.dart';
import 'package:mini_feed/data/models/user_model.dart';

class MockStorageService extends Mock implements StorageService {}
class MockTokenStorage extends Mock implements TokenStorage {}

void main() {
  group('AuthLocalDataSourceImpl', () {
    late AuthLocalDataSourceImpl dataSource;
    late MockStorageService mockStorageService;
    late MockTokenStorage mockTokenStorage;

    setUp(() {
      mockStorageService = MockStorageService();
      mockTokenStorage = MockTokenStorage();
      dataSource = AuthLocalDataSourceImpl(
        storageService: mockStorageService,
        tokenStorage: mockTokenStorage,
      );
    });

    group('storeAuthResponse', () {
      test('should store auth response successfully', () async {
        // Arrange
        const user = UserModel(
          id: 1,
          email: 'test@example.com',
          firstName: 'Test',
          lastName: 'User',
        );
        const authResponse = LoginResponseModel(
          user: user,
          token: 'test_token',
          refreshToken: 'refresh_token',
          expiresIn: 3600,
        );

        when(() => mockTokenStorage.storeAccessToken(any())).thenAnswer((_) async {});
        when(() => mockTokenStorage.storeRefreshToken(any())).thenAnswer((_) async {});
        when(() => mockStorageService.setString(any(), any())).thenAnswer((_) async {});
        when(() => mockStorageService.setBool(any(), any())).thenAnswer((_) async {});
        when(() => mockStorageService.setInt(any(), any())).thenAnswer((_) async {});

        // Act
        final result = await dataSource.storeAuthResponse(authResponse);

        // Assert
        expect(result.isSuccess, isTrue);
        verify(() => mockTokenStorage.storeAccessToken('test_token')).called(1);
        verify(() => mockTokenStorage.storeRefreshToken('refresh_token')).called(1);
        verify(() => mockStorageService.setString('user_profile', any())).called(1);
        verify(() => mockStorageService.setBool('is_authenticated', true)).called(1);
        verify(() => mockStorageService.setInt('last_login_time', any())).called(1);
        verify(() => mockStorageService.setInt('token_expiration', any())).called(1);
      });

      test('should handle auth response without refresh token', () async {
        // Arrange
        const user = UserModel(
          id: 1,
          email: 'test@example.com',
        );
        const authResponse = LoginResponseModel(
          user: user,
          token: 'test_token',
        );

        when(() => mockTokenStorage.storeAccessToken(any())).thenAnswer((_) async {});
        when(() => mockStorageService.setString(any(), any())).thenAnswer((_) async {});
        when(() => mockStorageService.setBool(any(), any())).thenAnswer((_) async {});
        when(() => mockStorageService.setInt(any(), any())).thenAnswer((_) async {});

        // Act
        final result = await dataSource.storeAuthResponse(authResponse);

        // Assert
        expect(result.isSuccess, isTrue);
        verify(() => mockTokenStorage.storeAccessToken('test_token')).called(1);
        verifyNever(() => mockTokenStorage.storeRefreshToken(any()));
      });

      test('should throw CacheException when storage fails', () async {
        // Arrange
        const user = UserModel(id: 1, email: 'test@example.com');
        const authResponse = LoginResponseModel(user: user, token: 'test_token');

        when(() => mockTokenStorage.storeAccessToken(any())).thenThrow(Exception('Storage error'));

        // Act & Assert
        expect(
          () => dataSource.storeAuthResponse(authResponse),
          throwsA(isA<CacheException>()),
        );
      });
    });

    group('getAccessToken', () {
      test('should return access token when available', () async {
        // Arrange
        when(() => mockTokenStorage.getAccessToken()).thenAnswer((_) async => 'test_token');

        // Act
        final result = await dataSource.getAccessToken();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.successValue, equals('test_token'));
        verify(() => mockTokenStorage.getAccessToken()).called(1);
      });

      test('should return null when no token available', () async {
        // Arrange
        when(() => mockTokenStorage.getAccessToken()).thenAnswer((_) async => null);

        // Act
        final result = await dataSource.getAccessToken();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.successValue, isNull);
      });

      test('should throw CacheException when storage fails', () async {
        // Arrange
        when(() => mockTokenStorage.getAccessToken()).thenThrow(Exception('Storage error'));

        // Act & Assert
        expect(
          () => dataSource.getAccessToken(),
          throwsA(isA<CacheException>()),
        );
      });
    });

    group('getRefreshToken', () {
      test('should return refresh token when available', () async {
        // Arrange
        when(() => mockTokenStorage.getRefreshToken()).thenAnswer((_) async => 'refresh_token');

        // Act
        final result = await dataSource.getRefreshToken();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.successValue, equals('refresh_token'));
        verify(() => mockTokenStorage.getRefreshToken()).called(1);
      });

      test('should return null when no refresh token available', () async {
        // Arrange
        when(() => mockTokenStorage.getRefreshToken()).thenAnswer((_) async => null);

        // Act
        final result = await dataSource.getRefreshToken();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.successValue, isNull);
      });
    });

    group('clearAuthData', () {
      test('should clear all authentication data', () async {
        // Arrange
        when(() => mockTokenStorage.clearTokens()).thenAnswer((_) async {});
        when(() => mockStorageService.remove(any())).thenAnswer((_) async {});
        when(() => mockStorageService.setBool(any(), any())).thenAnswer((_) async {});

        // Act
        final result = await dataSource.clearAuthData();

        // Assert
        expect(result.isSuccess, isTrue);
        verify(() => mockTokenStorage.clearTokens()).called(1);
        verify(() => mockStorageService.remove('user_profile')).called(1);
        verify(() => mockStorageService.setBool('is_authenticated', false)).called(1);
        verify(() => mockStorageService.remove('last_login_time')).called(1);
        verify(() => mockStorageService.remove('token_expiration')).called(1);
        verify(() => mockStorageService.remove('user_preferences')).called(1);
      });
    });

    group('storeUserProfile', () {
      test('should store user profile successfully', () async {
        // Arrange
        const user = UserModel(
          id: 1,
          email: 'test@example.com',
          firstName: 'Test',
          lastName: 'User',
        );

        when(() => mockStorageService.setString(any(), any())).thenAnswer((_) async {});

        // Act
        final result = await dataSource.storeUserProfile(user);

        // Assert
        expect(result.isSuccess, isTrue);
        verify(() => mockStorageService.setString('user_profile', any())).called(1);
      });
    });

    group('getUserProfile', () {
      test('should return user profile when available', () async {
        // Arrange
        const user = UserModel(
          id: 1,
          email: 'test@example.com',
          firstName: 'Test',
          lastName: 'User',
        );
        final userJson = user.toJsonString();

        when(() => mockStorageService.getString('user_profile'))
            .thenAnswer((_) async => userJson);

        // Act
        final result = await dataSource.getUserProfile();

        // Assert
        expect(result.isSuccess, isTrue);
        final retrievedUser = result.successValue!;
        expect(retrievedUser.id, equals(user.id));
        expect(retrievedUser.email, equals(user.email));
        expect(retrievedUser.firstName, equals(user.firstName));
        expect(retrievedUser.lastName, equals(user.lastName));
      });

      test('should return null when no user profile stored', () async {
        // Arrange
        when(() => mockStorageService.getString('user_profile'))
            .thenAnswer((_) async => null);

        // Act
        final result = await dataSource.getUserProfile();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.successValue, isNull);
      });
    });

    group('isAuthenticated', () {
      test('should return true when user is authenticated with valid token', () async {
        // Arrange
        when(() => mockTokenStorage.getAccessToken()).thenAnswer((_) async => 'test_token');
        when(() => mockStorageService.getInt('token_expiration'))
            .thenAnswer((_) async => DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch);
        when(() => mockStorageService.getBool('is_authenticated'))
            .thenAnswer((_) async => true);

        // Act
        final result = await dataSource.isAuthenticated();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.successValue, isTrue);
      });

      test('should return false when no access token', () async {
        // Arrange
        when(() => mockTokenStorage.getAccessToken()).thenAnswer((_) async => null);

        // Act
        final result = await dataSource.isAuthenticated();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.successValue, isFalse);
      });

      test('should return false when token is expired', () async {
        // Arrange
        when(() => mockTokenStorage.getAccessToken()).thenAnswer((_) async => 'test_token');
        when(() => mockStorageService.getInt('token_expiration'))
            .thenAnswer((_) async => DateTime.now().subtract(const Duration(hours: 1)).millisecondsSinceEpoch);

        // Act
        final result = await dataSource.isAuthenticated();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.successValue, isFalse);
      });

      test('should return false when authentication state is false', () async {
        // Arrange
        when(() => mockTokenStorage.getAccessToken()).thenAnswer((_) async => 'test_token');
        when(() => mockStorageService.getInt('token_expiration'))
            .thenAnswer((_) async => DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch);
        when(() => mockStorageService.getBool('is_authenticated'))
            .thenAnswer((_) async => false);

        // Act
        final result = await dataSource.isAuthenticated();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.successValue, isFalse);
      });
    });

    group('getLastLoginTime', () {
      test('should return last login time when available', () async {
        // Arrange
        final loginTime = DateTime.now();
        when(() => mockStorageService.getInt('last_login_time'))
            .thenAnswer((_) async => loginTime.millisecondsSinceEpoch);

        // Act
        final result = await dataSource.getLastLoginTime();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.successValue, equals(loginTime));
      });

      test('should return null when no login time stored', () async {
        // Arrange
        when(() => mockStorageService.getInt('last_login_time'))
            .thenAnswer((_) async => null);

        // Act
        final result = await dataSource.getLastLoginTime();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.successValue, isNull);
      });
    });

    group('isTokenExpired', () {
      test('should return true when token is expired', () async {
        // Arrange
        final expiredTime = DateTime.now().subtract(const Duration(hours: 1));
        when(() => mockStorageService.getInt('token_expiration'))
            .thenAnswer((_) async => expiredTime.millisecondsSinceEpoch);

        // Act
        final result = await dataSource.isTokenExpired();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.successValue, isTrue);
      });

      test('should return false when token is not expired', () async {
        // Arrange
        final futureTime = DateTime.now().add(const Duration(hours: 1));
        when(() => mockStorageService.getInt('token_expiration'))
            .thenAnswer((_) async => futureTime.millisecondsSinceEpoch);

        // Act
        final result = await dataSource.isTokenExpired();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.successValue, isFalse);
      });

      test('should return false when no expiration time stored', () async {
        // Arrange
        when(() => mockStorageService.getInt('token_expiration'))
            .thenAnswer((_) async => null);

        // Act
        final result = await dataSource.isTokenExpired();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.successValue, isFalse);
      });
    });

    group('biometric settings', () {
      test('should get biometric enabled setting', () async {
        // Arrange
        when(() => mockStorageService.getBool('biometric_enabled'))
            .thenAnswer((_) async => true);

        // Act
        final result = await dataSource.getBiometricEnabled();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.successValue, isTrue);
      });

      test('should return false when biometric setting not stored', () async {
        // Arrange
        when(() => mockStorageService.getBool('biometric_enabled'))
            .thenAnswer((_) async => null);

        // Act
        final result = await dataSource.getBiometricEnabled();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.successValue, isFalse);
      });

      test('should set biometric enabled setting', () async {
        // Arrange
        when(() => mockStorageService.setBool(any(), any())).thenAnswer((_) async {});

        // Act
        final result = await dataSource.setBiometricEnabled(true);

        // Assert
        expect(result.isSuccess, isTrue);
        verify(() => mockStorageService.setBool('biometric_enabled', true)).called(1);
      });
    });

    group('user preferences', () {
      test('should store user preferences', () async {
        // Arrange
        final preferences = {'theme': 'dark', 'notifications': true};
        when(() => mockStorageService.setString(any(), any())).thenAnswer((_) async {});

        // Act
        final result = await dataSource.storeUserPreferences(preferences);

        // Assert
        expect(result.isSuccess, isTrue);
        verify(() => mockStorageService.setString('user_preferences', any())).called(1);
      });

      test('should get user preferences', () async {
        // Arrange
        when(() => mockStorageService.getString('user_preferences'))
            .thenAnswer((_) async => 'preferences_string');

        // Act
        final result = await dataSource.getUserPreferences();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.successValue, isA<Map<String, dynamic>>());
      });

      test('should return empty map when no preferences stored', () async {
        // Arrange
        when(() => mockStorageService.getString('user_preferences'))
            .thenAnswer((_) async => null);

        // Act
        final result = await dataSource.getUserPreferences();

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.successValue, isEmpty);
      });
    });
  });
}