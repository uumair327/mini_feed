import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../lib/core/network/network_info.dart';
import '../../../lib/core/storage/storage_service.dart';
import '../../../lib/core/storage/token_storage.dart';
import '../../../lib/core/utils/result.dart';
import '../../../lib/core/errors/failures.dart';
import '../../../lib/core/errors/exceptions.dart';
import '../../../lib/domain/entities/user.dart';
import '../../../lib/data/repositories/auth_repository_impl.dart';
import '../../../lib/data/datasources/remote/auth_remote_datasource.dart';
import '../../../lib/data/models/user_model.dart';
import '../../../lib/data/models/login_response_model.dart';

// Mock classes
class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}
class MockStorageService extends Mock implements StorageService {}
class MockTokenStorage extends Mock implements TokenStorage {}
class MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  late AuthRepositoryImpl repository;
  late MockAuthRemoteDataSource mockRemoteDataSource;
  late MockStorageService mockStorageService;
  late MockTokenStorage mockTokenStorage;
  late MockNetworkInfo mockNetworkInfo;

  setUp(() {
    mockRemoteDataSource = MockAuthRemoteDataSource();
    mockStorageService = MockStorageService();
    mockTokenStorage = MockTokenStorage();
    mockNetworkInfo = MockNetworkInfo();
    
    repository = AuthRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      storageService: mockStorageService,
      tokenStorage: mockTokenStorage,
      networkInfo: mockNetworkInfo,
    );
  });

  group('login', () {
    const email = 'eve.holt@reqres.in';
    const password = 'cityslicka';
    const token = 'QpwL5tke4Pnpja7X4';
    
    final userModel = UserModel(
      id: 4,
      email: email,
      firstName: 'Eve',
      lastName: 'Holt',
      token: token,
    );
    
    final loginResponse = LoginResponseModel(
      user: userModel,
      token: token,
      expiresIn: 3600,
    );

    test('should return User when login is successful', () async {
      // Arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.login(
        email: email,
        password: password,
      )).thenAnswer((_) async => success(loginResponse));
      when(() => mockTokenStorage.storeToken(token)).thenAnswer((_) async {});
      when(() => mockStorageService.store('user_profile', any())).thenAnswer((_) async {});
      when(() => mockStorageService.store('is_authenticated', true)).thenAnswer((_) async {});
      when(() => mockStorageService.store('last_login_time', any())).thenAnswer((_) async {});

      // Act
      final result = await repository.login(email: email, password: password);

      // Assert
      expect(result.isSuccess, true);
      expect(result.successValue, isA<User>());
      expect(result.successValue!.email, email);
      expect(result.successValue!.token, token);
      
      verify(() => mockNetworkInfo.isConnected).called(1);
      verify(() => mockRemoteDataSource.login(
        email: email,
        password: password,
      )).called(1);
      verify(() => mockTokenStorage.storeToken(token)).called(1);
    });

    test('should return NetworkFailure when no internet connection', () async {
      // Arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      // Act
      final result = await repository.login(email: email, password: password);

      // Assert
      expect(result.isFailure, true);
      expect(result.failureValue, isA<NetworkFailure>());
      expect(result.failureValue!.message, 'No internet connection');
      
      verify(() => mockNetworkInfo.isConnected).called(1);
      verifyNever(() => mockRemoteDataSource.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ));
    });

    test('should return AuthFailure when remote login fails', () async {
      // Arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.login(
        email: email,
        password: password,
      )).thenAnswer((_) async => failure(const AuthFailure('Invalid credentials')));

      // Act
      final result = await repository.login(email: email, password: password);

      // Assert
      expect(result.isFailure, true);
      expect(result.failureValue, isA<AuthFailure>());
      expect(result.failureValue!.message, 'Invalid credentials');
      
      verify(() => mockNetworkInfo.isConnected).called(1);
      verify(() => mockRemoteDataSource.login(
        email: email,
        password: password,
      )).called(1);
      verifyNever(() => mockTokenStorage.storeToken(any()));
    });

    test('should handle storage failure during login', () async {
      // Arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.login(
        email: email,
        password: password,
      )).thenAnswer((_) async => success(loginResponse));
      when(() => mockTokenStorage.storeToken(token)).thenThrow(const CacheException('Storage failed'));

      // Act
      final result = await repository.login(email: email, password: password);

      // Assert
      expect(result.isFailure, true);
      expect(result.failureValue, isA<CacheFailure>());
      
      verify(() => mockTokenStorage.storeToken(token)).called(1);
    });

    test('should handle ServerException and return ServerFailure', () async {
      // Arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.login(
        email: email,
        password: password,
      )).thenThrow(const ServerException('Server error', 500));

      // Act
      final result = await repository.login(email: email, password: password);

      // Assert
      expect(result.isFailure, true);
      expect(result.failureValue, isA<ServerFailure>());
      expect(result.failureValue!.message, 'Server error');
    });
  });

  group('logout', () {
    test('should return success when logout is successful', () async {
      // Arrange
      when(() => mockTokenStorage.clearAllTokens()).thenAnswer((_) async {});
      when(() => mockStorageService.delete('user_profile')).thenAnswer((_) async {});
      when(() => mockStorageService.delete('is_authenticated')).thenAnswer((_) async {});
      when(() => mockStorageService.delete('last_login_time')).thenAnswer((_) async {});

      // Act
      final result = await repository.logout();

      // Assert
      expect(result.isSuccess, true);
      verify(() => mockTokenStorage.clearAllTokens()).called(1);
      verify(() => mockStorageService.delete('user_profile')).called(1);
    });

    test('should handle CacheException and return CacheFailure', () async {
      // Arrange
      when(() => mockTokenStorage.clearAllTokens())
          .thenThrow(const CacheException('Cache error'));

      // Act
      final result = await repository.logout();

      // Assert
      expect(result.isFailure, true);
      expect(result.failureValue, isA<CacheFailure>());
      expect(result.failureValue!.message, contains('Cache error'));
    });
  });

  group('getStoredToken', () {
    const token = 'stored_token';

    test('should return token when token exists', () async {
      // Arrange
      when(() => mockTokenStorage.getToken()).thenAnswer((_) async => token);

      // Act
      final result = await repository.getStoredToken();

      // Assert
      expect(result.isSuccess, true);
      expect(result.successValue, token);
      verify(() => mockTokenStorage.getToken()).called(1);
    });

    test('should return null when no token exists', () async {
      // Arrange
      when(() => mockTokenStorage.getToken()).thenAnswer((_) async => null);

      // Act
      final result = await repository.getStoredToken();

      // Assert
      expect(result.isSuccess, true);
      expect(result.successValue, null);
    });

    test('should handle exception and return UnexpectedFailure', () async {
      // Arrange
      when(() => mockTokenStorage.getToken())
          .thenThrow(Exception('Token retrieval failed'));

      // Act
      final result = await repository.getStoredToken();

      // Assert
      expect(result.isFailure, true);
      expect(result.failureValue, isA<UnexpectedFailure>());
    });
  });

  group('isAuthenticated', () {
    test('should return true when user has valid token', () async {
      // Arrange
      when(() => mockTokenStorage.hasToken()).thenAnswer((_) async => true);

      // Act
      final result = await repository.isAuthenticated();

      // Assert
      expect(result.isSuccess, true);
      expect(result.successValue, true);
      verify(() => mockTokenStorage.hasToken()).called(1);
    });

    test('should return false when user has no token', () async {
      // Arrange
      when(() => mockTokenStorage.hasToken()).thenAnswer((_) async => false);

      // Act
      final result = await repository.isAuthenticated();

      // Assert
      expect(result.isSuccess, true);
      expect(result.successValue, false);
    });

    test('should handle exception and return UnexpectedFailure', () async {
      // Arrange
      when(() => mockTokenStorage.hasToken())
          .thenThrow(Exception('Auth check failed'));

      // Act
      final result = await repository.isAuthenticated();

      // Assert
      expect(result.isFailure, true);
      expect(result.failureValue, isA<UnexpectedFailure>());
    });
  });

  group('getCurrentUser', () {
    const token = 'user_token';
    final userModel = UserModel(
      id: 1,
      email: 'test@example.com',
      firstName: 'Test',
      lastName: 'User',
    );

    test('should return User when authenticated and user exists', () async {
      // Arrange
      when(() => mockTokenStorage.hasToken()).thenAnswer((_) async => true);
      when(() => mockStorageService.get<String>('user_profile'))
          .thenAnswer((_) async => userModel.toJsonString());
      when(() => mockTokenStorage.getToken()).thenAnswer((_) async => token);

      // Act
      final result = await repository.getCurrentUser();

      // Assert
      expect(result.isSuccess, true);
      expect(result.successValue, isA<User>());
      expect(result.successValue!.email, userModel.email);
      expect(result.successValue!.token, token);
    });

    test('should return null when user is not authenticated', () async {
      // Arrange
      when(() => mockTokenStorage.hasToken()).thenAnswer((_) async => false);

      // Act
      final result = await repository.getCurrentUser();

      // Assert
      expect(result.isSuccess, true);
      expect(result.successValue, null);
      
      verify(() => mockTokenStorage.hasToken()).called(1);
      verifyNever(() => mockStorageService.get<String>('user_profile'));
    });

    test('should return null when user profile does not exist', () async {
      // Arrange
      when(() => mockTokenStorage.hasToken()).thenAnswer((_) async => true);
      when(() => mockStorageService.get<String>('user_profile'))
          .thenAnswer((_) async => null);

      // Act
      final result = await repository.getCurrentUser();

      // Assert
      expect(result.isSuccess, true);
      expect(result.successValue, null);
    });
  });

  group('validateToken', () {
    const token = 'valid_token';

    test('should return false when no token exists', () async {
      // Arrange
      when(() => mockTokenStorage.getToken()).thenAnswer((_) async => null);

      // Act
      final result = await repository.validateToken();

      // Assert
      expect(result.isSuccess, true);
      expect(result.successValue, false);
    });

    test('should return true when token exists (offline)', () async {
      // Arrange
      when(() => mockTokenStorage.getToken()).thenAnswer((_) async => token);
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      // Act
      final result = await repository.validateToken();

      // Assert
      expect(result.isSuccess, true);
      expect(result.successValue, true);
    });

    test('should return true when token exists (online)', () async {
      // Arrange
      when(() => mockTokenStorage.getToken()).thenAnswer((_) async => token);
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);

      // Act
      final result = await repository.validateToken();

      // Assert
      expect(result.isSuccess, true);
      expect(result.successValue, true);
    });
  });

  group('refreshToken', () {
    test('should return AuthFailure when no refresh token exists', () async {
      // Arrange
      when(() => mockTokenStorage.getRefreshToken()).thenAnswer((_) async => null);

      // Act
      final result = await repository.refreshToken();

      // Assert
      expect(result.isFailure, true);
      expect(result.failureValue, isA<AuthFailure>());
      expect(result.failureValue!.message, 'No refresh token available');
    });

    test('should return NetworkFailure when no internet connection', () async {
      // Arrange
      when(() => mockTokenStorage.getRefreshToken())
          .thenAnswer((_) async => 'refresh_token');
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      // Act
      final result = await repository.refreshToken();

      // Assert
      expect(result.isFailure, true);
      expect(result.failureValue, isA<NetworkFailure>());
      expect(result.failureValue!.message, 'No internet connection');
    });

    test('should return AuthFailure for unsupported refresh token', () async {
      // Arrange
      when(() => mockTokenStorage.getRefreshToken())
          .thenAnswer((_) async => 'refresh_token');
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);

      // Act
      final result = await repository.refreshToken();

      // Assert
      expect(result.isFailure, true);
      expect(result.failureValue, isA<AuthFailure>());
      expect(result.failureValue!.message, 'Token refresh not supported by API');
    });
  });
}