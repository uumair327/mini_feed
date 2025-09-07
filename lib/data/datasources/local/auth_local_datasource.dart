import '../../../core/storage/storage_service.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/utils/result.dart';
import '../../../core/errors/exceptions.dart';
import '../../models/user_model.dart';
import '../../models/login_response_model.dart';

/// Local data source for authentication operations
/// 
/// Handles local storage of authentication data including tokens,
/// user profile, and authentication state for offline access and security.
abstract class AuthLocalDataSource {
  /// Store authentication response (tokens and user data)
  Future<Result<void>> storeAuthResponse(LoginResponseModel authResponse);

  /// Get stored access token
  Future<Result<String?>> getAccessToken();

  /// Get stored refresh token
  Future<Result<String?>> getRefreshToken();

  /// Store access token
  Future<Result<void>> storeAccessToken(String token);

  /// Store refresh token
  Future<Result<void>> storeRefreshToken(String token);

  /// Clear all authentication data
  Future<Result<void>> clearAuthData();

  /// Store user profile data
  Future<Result<void>> storeUserProfile(UserModel user);

  /// Get stored user profile
  Future<Result<UserModel?>> getUserProfile();

  /// Check if user is authenticated (has valid token)
  Future<Result<bool>> isAuthenticated();

  /// Store authentication state
  Future<Result<void>> setAuthenticationState(bool isAuthenticated);

  /// Get last login timestamp
  Future<Result<DateTime?>> getLastLoginTime();

  /// Store login timestamp
  Future<Result<void>> storeLoginTime(DateTime loginTime);

  /// Store user preferences
  Future<Result<void>> storeUserPreferences(Map<String, dynamic> preferences);

  /// Get user preferences
  Future<Result<Map<String, dynamic>>> getUserPreferences();

  /// Check if token is expired
  Future<Result<bool>> isTokenExpired();

  /// Store token expiration time
  Future<Result<void>> storeTokenExpiration(DateTime expirationTime);

  /// Get biometric authentication preference
  Future<Result<bool>> getBiometricEnabled();

  /// Set biometric authentication preference
  Future<Result<void>> setBiometricEnabled(bool enabled);
}

/// Implementation of AuthLocalDataSource
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final StorageService storageService;
  final TokenStorage tokenStorage;

  const AuthLocalDataSourceImpl({
    required this.storageService,
    required this.tokenStorage,
  });

  @override
  Future<Result<void>> storeAuthResponse(LoginResponseModel authResponse) async {
    try {
      // Store tokens securely
      await tokenStorage.storeAccessToken(authResponse.token);
      if (authResponse.refreshToken != null) {
        await tokenStorage.storeRefreshToken(authResponse.refreshToken!);
      }

      // Store user profile
      await _storeUserProfile(authResponse.user);

      // Store authentication state
      await _setAuthenticationState(true);

      // Store login time
      await _storeLoginTime(DateTime.now());

      // Calculate and store token expiration
      if (authResponse.expiresIn != null) {
        final expirationTime = DateTime.now().add(Duration(seconds: authResponse.expiresIn!));
        await _storeTokenExpiration(expirationTime);
      }

      return success(null);
    } catch (e) {
      throw CacheException('Failed to store auth response: $e');
    }
  }

  @override
  Future<Result<String?>> getAccessToken() async {
    try {
      final token = await tokenStorage.getAccessToken();
      return success(token);
    } catch (e) {
      throw CacheException('Failed to get access token: $e');
    }
  }

  @override
  Future<Result<String?>> getRefreshToken() async {
    try {
      final token = await tokenStorage.getRefreshToken();
      return success(token);
    } catch (e) {
      throw CacheException('Failed to get refresh token: $e');
    }
  }

  @override
  Future<Result<void>> storeAccessToken(String token) async {
    try {
      await tokenStorage.storeAccessToken(token);
      return success(null);
    } catch (e) {
      throw CacheException('Failed to store access token: $e');
    }
  }

  @override
  Future<Result<void>> storeRefreshToken(String token) async {
    try {
      await tokenStorage.storeRefreshToken(token);
      return success(null);
    } catch (e) {
      throw CacheException('Failed to store refresh token: $e');
    }
  }

  @override
  Future<Result<void>> clearAuthData() async {
    try {
      // Clear tokens
      await tokenStorage.clearTokens();

      // Clear user profile
      await storageService.remove('user_profile');

      // Clear authentication state
      await _setAuthenticationState(false);

      // Clear login time
      await storageService.remove('last_login_time');

      // Clear token expiration
      await storageService.remove('token_expiration');

      // Clear user preferences (optional - might want to keep some)
      await storageService.remove('user_preferences');

      return success(null);
    } catch (e) {
      throw CacheException('Failed to clear auth data: $e');
    }
  }

  @override
  Future<Result<void>> storeUserProfile(UserModel user) async {
    try {
      await _storeUserProfile(user);
      return success(null);
    } catch (e) {
      throw CacheException('Failed to store user profile: $e');
    }
  }

  @override
  Future<Result<UserModel?>> getUserProfile() async {
    try {
      final userJson = await storageService.getString('user_profile');
      if (userJson == null) return success(null);

      final user = UserModel.fromJsonString(userJson);
      return success(user);
    } catch (e) {
      throw CacheException('Failed to get user profile: $e');
    }
  }

  @override
  Future<Result<bool>> isAuthenticated() async {
    try {
      // Check if we have a valid access token
      final tokenResult = await getAccessToken();
      if (tokenResult.isFailure || tokenResult.successValue == null) {
        return success(false);
      }

      // Check if token is expired
      final expiredResult = await isTokenExpired();
      if (expiredResult.isSuccess && expiredResult.successValue == true) {
        return success(false);
      }

      // Check stored authentication state
      final isAuth = await storageService.getBool('is_authenticated') ?? false;
      return success(isAuth);
    } catch (e) {
      throw CacheException('Failed to check authentication status: $e');
    }
  }

  @override
  Future<Result<void>> setAuthenticationState(bool isAuthenticated) async {
    try {
      await _setAuthenticationState(isAuthenticated);
      return success(null);
    } catch (e) {
      throw CacheException('Failed to set authentication state: $e');
    }
  }

  @override
  Future<Result<DateTime?>> getLastLoginTime() async {
    try {
      final timestamp = await storageService.getInt('last_login_time');
      if (timestamp == null) return success(null);

      final loginTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      return success(loginTime);
    } catch (e) {
      throw CacheException('Failed to get last login time: $e');
    }
  }

  @override
  Future<Result<void>> storeLoginTime(DateTime loginTime) async {
    try {
      await _storeLoginTime(loginTime);
      return success(null);
    } catch (e) {
      throw CacheException('Failed to store login time: $e');
    }
  }

  @override
  Future<Result<void>> storeUserPreferences(Map<String, dynamic> preferences) async {
    try {
      final preferencesJson = preferences.toString(); // In a real app, use proper JSON encoding
      await storageService.setString('user_preferences', preferencesJson);
      return success(null);
    } catch (e) {
      throw CacheException('Failed to store user preferences: $e');
    }
  }

  @override
  Future<Result<Map<String, dynamic>>> getUserPreferences() async {
    try {
      final preferencesString = await storageService.getString('user_preferences');
      if (preferencesString == null) return success(<String, dynamic>{});

      // In a real app, you'd use proper JSON decoding
      // For now, return empty map as placeholder
      return success(<String, dynamic>{});
    } catch (e) {
      throw CacheException('Failed to get user preferences: $e');
    }
  }

  @override
  Future<Result<bool>> isTokenExpired() async {
    try {
      final expirationTimestamp = await storageService.getInt('token_expiration');
      if (expirationTimestamp == null) return success(false);

      final expirationTime = DateTime.fromMillisecondsSinceEpoch(expirationTimestamp);
      final isExpired = DateTime.now().isAfter(expirationTime);
      return success(isExpired);
    } catch (e) {
      throw CacheException('Failed to check token expiration: $e');
    }
  }

  @override
  Future<Result<void>> storeTokenExpiration(DateTime expirationTime) async {
    try {
      await _storeTokenExpiration(expirationTime);
      return success(null);
    } catch (e) {
      throw CacheException('Failed to store token expiration: $e');
    }
  }

  @override
  Future<Result<bool>> getBiometricEnabled() async {
    try {
      final enabled = await storageService.getBool('biometric_enabled') ?? false;
      return success(enabled);
    } catch (e) {
      throw CacheException('Failed to get biometric setting: $e');
    }
  }

  @override
  Future<Result<void>> setBiometricEnabled(bool enabled) async {
    try {
      await storageService.setBool('biometric_enabled', enabled);
      return success(null);
    } catch (e) {
      throw CacheException('Failed to set biometric setting: $e');
    }
  }

  // Private helper methods
  Future<void> _storeUserProfile(UserModel user) async {
    await storageService.setString('user_profile', user.toJsonString());
  }

  Future<void> _setAuthenticationState(bool isAuthenticated) async {
    await storageService.setBool('is_authenticated', isAuthenticated);
  }

  Future<void> _storeLoginTime(DateTime loginTime) async {
    await storageService.setInt('last_login_time', loginTime.millisecondsSinceEpoch);
  }

  Future<void> _storeTokenExpiration(DateTime expirationTime) async {
    await storageService.setInt('token_expiration', expirationTime.millisecondsSinceEpoch);
  }
}