import 'package:flutter_test/flutter_test.dart';
import 'package:mini_feed/core/storage/storage_service.dart';
import 'package:mini_feed/core/storage/token_storage.dart';

// Mock storage service for testing
class MockStorageService implements StorageService {
  final Map<String, dynamic> _storage = {};
  final Map<String, String> _secureStorage = {};
  
  @override
  Future<void> initialize() async {}
  
  @override
  Future<void> store(String key, dynamic value) async {
    _storage[key] = value;
  }
  
  @override
  Future<T?> get<T>(String key) async {
    return _storage[key] as T?;
  }
  
  @override
  Future<void> delete(String key) async {
    _storage.remove(key);
  }
  
  @override
  Future<void> clear() async {
    _storage.clear();
  }
  
  @override
  Future<void> storeSecure(String key, String value) async {
    _secureStorage[key] = value;
  }
  
  @override
  Future<String?> getSecure(String key) async {
    return _secureStorage[key];
  }
  
  @override
  Future<void> deleteSecure(String key) async {
    _secureStorage.remove(key);
  }
  
  @override
  Future<void> clearSecure() async {
    _secureStorage.clear();
  }
  
  @override
  Future<void> dispose() async {}
}

void main() {
  late TokenStorage tokenStorage;
  late MockStorageService mockStorageService;
  
  setUp(() {
    mockStorageService = MockStorageService();
    tokenStorage = TokenStorageImpl(mockStorageService);
  });
  
  group('TokenStorage', () {
    test('should store and retrieve access token', () async {
      // Arrange
      const token = 'test_access_token_123';
      
      // Act
      await tokenStorage.storeToken(token);
      final retrievedToken = await tokenStorage.getToken();
      
      // Assert
      expect(retrievedToken, equals(token));
    });
    
    test('should return null when no token is stored', () async {
      // Act
      final token = await tokenStorage.getToken();
      
      // Assert
      expect(token, isNull);
    });
    
    test('should delete access token', () async {
      // Arrange
      const token = 'test_access_token_123';
      
      // Act
      await tokenStorage.storeToken(token);
      await tokenStorage.deleteToken();
      final retrievedToken = await tokenStorage.getToken();
      
      // Assert
      expect(retrievedToken, isNull);
    });
    
    test('should check if token exists', () async {
      // Arrange
      const token = 'test_access_token_123';
      
      // Act & Assert - No token initially
      expect(await tokenStorage.hasToken(), isFalse);
      
      // Store token
      await tokenStorage.storeToken(token);
      expect(await tokenStorage.hasToken(), isTrue);
      
      // Delete token
      await tokenStorage.deleteToken();
      expect(await tokenStorage.hasToken(), isFalse);
    });
    
    test('should store and retrieve refresh token', () async {
      // Arrange
      const refreshToken = 'test_refresh_token_456';
      
      // Act
      await tokenStorage.storeRefreshToken(refreshToken);
      final retrievedToken = await tokenStorage.getRefreshToken();
      
      // Assert
      expect(retrievedToken, equals(refreshToken));
    });
    
    test('should return null when no refresh token is stored', () async {
      // Act
      final refreshToken = await tokenStorage.getRefreshToken();
      
      // Assert
      expect(refreshToken, isNull);
    });
    
    test('should delete refresh token', () async {
      // Arrange
      const refreshToken = 'test_refresh_token_456';
      
      // Act
      await tokenStorage.storeRefreshToken(refreshToken);
      await tokenStorage.deleteRefreshToken();
      final retrievedToken = await tokenStorage.getRefreshToken();
      
      // Assert
      expect(retrievedToken, isNull);
    });
    
    test('should clear all tokens', () async {
      // Arrange
      const accessToken = 'test_access_token_123';
      const refreshToken = 'test_refresh_token_456';
      
      // Act
      await tokenStorage.storeToken(accessToken);
      await tokenStorage.storeRefreshToken(refreshToken);
      await tokenStorage.clearAllTokens();
      
      final retrievedAccessToken = await tokenStorage.getToken();
      final retrievedRefreshToken = await tokenStorage.getRefreshToken();
      
      // Assert
      expect(retrievedAccessToken, isNull);
      expect(retrievedRefreshToken, isNull);
    });
    
    test('should handle empty token correctly', () async {
      // Arrange
      const emptyToken = '';
      
      // Act
      await tokenStorage.storeToken(emptyToken);
      final hasToken = await tokenStorage.hasToken();
      
      // Assert
      expect(hasToken, isFalse);
    });
    
    test('should handle token expiry check', () async {
      // This test verifies the method exists and doesn't throw
      // In a real implementation, we'd test the actual expiry logic
      
      // Arrange
      const token = 'test_token';
      final tokenStorageImpl = tokenStorage as TokenStorageImpl;
      
      // Act & Assert
      expect(() => tokenStorageImpl.isTokenExpired(), returnsNormally);
      
      // Store a token and check expiry
      await tokenStorage.storeToken(token);
      final isExpired = await tokenStorageImpl.isTokenExpired(
        maxAge: const Duration(seconds: 1),
      );
      
      // Should not be expired immediately
      expect(isExpired, isFalse);
    });
    
    test('should get token creation time', () async {
      // Arrange
      const token = 'test_token';
      final tokenStorageImpl = tokenStorage as TokenStorageImpl;
      final beforeStore = DateTime.now();
      
      // Act
      await tokenStorage.storeToken(token);
      final creationTime = await tokenStorageImpl.getTokenCreationTime();
      final afterStore = DateTime.now();
      
      // Assert
      expect(creationTime, isNotNull);
      expect(creationTime!.isAfter(beforeStore.subtract(const Duration(seconds: 1))), isTrue);
      expect(creationTime.isBefore(afterStore.add(const Duration(seconds: 1))), isTrue);
    });
    
    test('should return null creation time when no token stored', () async {
      // Arrange
      final tokenStorageImpl = tokenStorage as TokenStorageImpl;
      
      // Act
      final creationTime = await tokenStorageImpl.getTokenCreationTime();
      
      // Assert
      expect(creationTime, isNull);
    });
  });
}
