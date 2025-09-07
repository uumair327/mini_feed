import '../utils/logger.dart';
import 'storage_service.dart';

/// Abstract interface for token storage operations
abstract class TokenStorage {
  Future<void> storeToken(String token);
  Future<String?> getToken();
  Future<void> deleteToken();
  Future<bool> hasToken();
  Future<void> storeRefreshToken(String refreshToken);
  Future<String?> getRefreshToken();
  Future<void> deleteRefreshToken();
  Future<void> clearAllTokens();
}

/// Implementation of TokenStorage using secure storage
class TokenStorageImpl implements TokenStorage {
  TokenStorageImpl(this._storageService);

  final StorageService _storageService;
  
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenExpiryKey = 'token_expiry';
  
  @override
  Future<void> storeToken(String token) async {
    try {
      await _storageService.storeSecure(_accessTokenKey, token);
      
      // Store token creation time for expiry tracking
      final now = DateTime.now().millisecondsSinceEpoch.toString();
      await _storageService.storeSecure(_tokenExpiryKey, now);
      
      Logger.debug('Access token stored securely');
    } on Exception catch (e) {
      Logger.error('Failed to store access token', e);
      rethrow;
    }
  }
  
  @override
  Future<String?> getToken() async {
    try {
      final token = await _storageService.getSecure(_accessTokenKey);
      
      if (token != null) {
        Logger.debug('Access token retrieved from secure storage');
      } else {
        Logger.debug('No access token found in secure storage');
      }
      
      return token;
    } on Exception catch (e) {
      Logger.error('Failed to retrieve access token', e);
      return null;
    }
  }
  
  @override
  Future<void> deleteToken() async {
    try {
      await _storageService.deleteSecure(_accessTokenKey);
      await _storageService.deleteSecure(_tokenExpiryKey);
      Logger.debug('Access token deleted from secure storage');
    } on Exception catch (e) {
      Logger.error('Failed to delete access token', e);
      rethrow;
    }
  }
  
  @override
  Future<bool> hasToken() async {
    try {
      final token = await getToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      Logger.error('Failed to check token existence', e);
      return false;
    }
  }
  
  @override
  Future<void> storeRefreshToken(String refreshToken) async {
    try {
      await _storageService.storeSecure(_refreshTokenKey, refreshToken);
      Logger.debug('Refresh token stored securely');
    } on Exception catch (e) {
      Logger.error('Failed to store refresh token', e);
      rethrow;
    }
  }
  
  @override
  Future<String?> getRefreshToken() async {
    try {
      final refreshToken = await _storageService.getSecure(_refreshTokenKey);
      
      if (refreshToken != null) {
        Logger.debug('Refresh token retrieved from secure storage');
      } else {
        Logger.debug('No refresh token found in secure storage');
      }
      
      return refreshToken;
    } on Exception catch (e) {
      Logger.error('Failed to retrieve refresh token', e);
      return null;
    }
  }
  
  @override
  Future<void> deleteRefreshToken() async {
    try {
      await _storageService.deleteSecure(_refreshTokenKey);
      Logger.debug('Refresh token deleted from secure storage');
    } catch (e) {
      Logger.error('Failed to delete refresh token', e);
      rethrow;
    }
  }
  
  @override
  Future<void> clearAllTokens() async {
    try {
      await deleteToken();
      await deleteRefreshToken();
      Logger.debug('All tokens cleared from secure storage');
    } on Exception catch (e) {
      Logger.error('Failed to clear all tokens', e);
      rethrow;
    }
  }
  
  /// Check if the stored token is expired (basic check based on storage time)
  Future<bool> isTokenExpired({
    Duration maxAge = const Duration(hours: 24),
  }) async {
    try {
      final expiryString = await _storageService.getSecure(_tokenExpiryKey);
      
      if (expiryString == null) {
        return true; // No expiry info means expired
      }
      
      final storedTime = DateTime.fromMillisecondsSinceEpoch(
        int.parse(expiryString),
      );
      
      final now = DateTime.now();
      final isExpired = now.difference(storedTime) > maxAge;
      
      if (isExpired) {
        Logger.debug('Token is expired');
      }
      
      return isExpired;
    } catch (e) {
      Logger.error('Failed to check token expiry', e);
      return true; // Assume expired on error
    }
  }
  
  /// Get token creation time
  Future<DateTime?> getTokenCreationTime() async {
    try {
      final expiryString = await _storageService.getSecure(_tokenExpiryKey);
      
      if (expiryString == null) {
        return null;
      }
      
      return DateTime.fromMillisecondsSinceEpoch(int.parse(expiryString));
    } catch (e) {
      Logger.error('Failed to get token creation time', e);
      return null;
    }
  }
}
