import '../../core/network/network_info.dart';
import '../../core/storage/storage_service.dart';
import '../../core/storage/token_storage.dart';
import '../../core/utils/result.dart';
import '../../core/errors/failures.dart';
import '../../core/errors/exceptions.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/remote/auth_remote_datasource.dart';
import '../models/user_model.dart';

/// Implementation of AuthRepository
/// 
/// Handles authentication operations by coordinating between remote and local data sources.
/// Implements offline-first approach with proper error handling and token management.
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final StorageService storageService;
  final TokenStorage tokenStorage;
  final NetworkInfo networkInfo;

  const AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.storageService,
    required this.tokenStorage,
    required this.networkInfo,
  });

  @override
  Future<Result<User>> login({
    required String email,
    required String password,
  }) async {
    try {
      // Check network connectivity
      if (!await networkInfo.isConnected) {
        return failure(const NetworkFailure('No internet connection'));
      }

      // Attempt login with remote data source
      final loginResult = await remoteDataSource.login(
        email: email,
        password: password,
      );

      if (loginResult.isFailure) {
        return failure(loginResult.failureValue!);
      }

      final loginResponse = loginResult.successValue!;

      // Store authentication data locally
      await _storeAuthData(loginResponse);

      return success(loginResponse.toDomain());
    } on ServerException catch (e) {
      return failure(ServerFailure(e.message, e.statusCode));
    } on NetworkException catch (e) {
      return failure(NetworkFailure(e.message));
    } on AuthException catch (e) {
      return failure(AuthFailure(e.message));
    } on CacheException catch (e) {
      return failure(CacheFailure(e.message));
    } catch (e) {
      return failure(UnexpectedFailure('Login failed: $e'));
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      // Clear all authentication data from local storage
      await _clearAuthData();
      return success(null);
    } on CacheException catch (e) {
      return failure(CacheFailure(e.message));
    } catch (e) {
      return failure(UnexpectedFailure('Logout failed: $e'));
    }
  }

  @override
  Future<Result<String?>> getStoredToken() async {
    try {
      final token = await tokenStorage.getToken();
      return success(token);
    } on CacheException catch (e) {
      return failure(CacheFailure(e.message));
    } catch (e) {
      return failure(UnexpectedFailure('Failed to get stored token: $e'));
    }
  }

  @override
  Future<Result<bool>> isAuthenticated() async {
    try {
      final hasToken = await tokenStorage.hasToken();
      if (!hasToken) {
        return success(false);
      }

      // Check if token is expired (if TokenStorage supports it)
      if (tokenStorage is TokenStorageImpl) {
        final isExpired = await (tokenStorage as TokenStorageImpl).isTokenExpired();
        if (isExpired) {
          return success(false);
        }
      }

      return success(true);
    } on CacheException catch (e) {
      return failure(CacheFailure(e.message));
    } catch (e) {
      return failure(UnexpectedFailure('Failed to check authentication status: $e'));
    }
  }

  @override
  Future<Result<User?>> getCurrentUser() async {
    try {
      // First check if user is authenticated
      final authResult = await isAuthenticated();
      if (authResult.isFailure) {
        return failure(authResult.failureValue!);
      }

      if (!authResult.successValue!) {
        return success(null);
      }

      // Get user profile from local storage
      final userJson = await storageService.get<String>('user_profile');
      if (userJson == null) {
        return success(null);
      }

      final userModel = UserModel.fromJsonString(userJson);

      // Get the stored token and add it to the user
      final tokenResult = await getStoredToken();
      if (tokenResult.isFailure) {
        return failure(tokenResult.failureValue!);
      }

      final user = userModel.toDomain().copyWith(token: tokenResult.successValue);
      return success(user);
    } on CacheException catch (e) {
      return failure(CacheFailure(e.message));
    } catch (e) {
      return failure(UnexpectedFailure('Failed to get current user: $e'));
    }
  }

  @override
  Future<Result<User>> refreshToken() async {
    try {
      // Check if we have a refresh token
      final refreshToken = await tokenStorage.getRefreshToken();
      if (refreshToken == null) {
        return failure(const AuthFailure('No refresh token available'));
      }

      // Check network connectivity
      if (!await networkInfo.isConnected) {
        return failure(const NetworkFailure('No internet connection'));
      }

      // Note: reqres.in doesn't support refresh tokens, so this is a placeholder
      // In a real app, you would call the refresh token endpoint here
      return failure(const AuthFailure('Token refresh not supported by API'));
    } on NetworkException catch (e) {
      return failure(NetworkFailure(e.message));
    } on AuthException catch (e) {
      return failure(AuthFailure(e.message));
    } on CacheException catch (e) {
      return failure(CacheFailure(e.message));
    } catch (e) {
      return failure(UnexpectedFailure('Token refresh failed: $e'));
    }
  }

  @override
  Future<Result<bool>> validateToken() async {
    try {
      // Get stored token
      final tokenResult = await getStoredToken();
      if (tokenResult.isFailure) {
        return failure(tokenResult.failureValue!);
      }

      final token = tokenResult.successValue;
      if (token == null) {
        return success(false);
      }

      // Check if token is expired locally first
      if (tokenStorage is TokenStorageImpl) {
        final isExpired = await (tokenStorage as TokenStorageImpl).isTokenExpired();
        if (isExpired) {
          return success(false);
        }
      }

      // Check network connectivity
      if (!await networkInfo.isConnected) {
        // If offline, assume token is valid if it exists and isn't expired locally
        return success(true);
      }

      // Note: reqres.in doesn't have a token validation endpoint
      // In a real app, you would make a request to validate the token here
      // For now, we'll just check if we have a token and it's not expired
      return success(true);
    } on NetworkException catch (e) {
      return failure(NetworkFailure(e.message));
    } on CacheException catch (e) {
      return failure(CacheFailure(e.message));
    } catch (e) {
      return failure(UnexpectedFailure('Token validation failed: $e'));
    }
  }

  /// Helper method to store authentication data
  Future<void> _storeAuthData(dynamic loginResponse) async {
    try {
      // Store tokens
      await tokenStorage.storeToken(loginResponse.token);
      if (loginResponse.refreshToken != null) {
        await tokenStorage.storeRefreshToken(loginResponse.refreshToken!);
      }

      // Store user profile
      await storageService.store('user_profile', loginResponse.user.toJsonString());

      // Store authentication state
      await storageService.store('is_authenticated', true);

      // Store login time
      await storageService.store('last_login_time', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      throw CacheException('Failed to store auth data: $e');
    }
  }

  /// Helper method to clear authentication data
  Future<void> _clearAuthData() async {
    try {
      // Clear tokens
      await tokenStorage.clearAllTokens();

      // Clear user profile
      await storageService.delete('user_profile');

      // Clear authentication state
      await storageService.delete('is_authenticated');

      // Clear login time
      await storageService.delete('last_login_time');
    } catch (e) {
      throw CacheException('Failed to clear auth data: $e');
    }
  }
}