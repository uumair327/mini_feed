import '../entities/user.dart';
import '../../core/utils/result.dart';
import '../../core/errors/failures.dart';

/// Repository interface for authentication operations
/// 
/// This repository handles all authentication-related operations including
/// login, logout, token management, and authentication state checking.
/// 
/// All methods return [Result] objects to handle success and failure cases
/// in a type-safe manner without throwing exceptions.
abstract class AuthRepository {
  /// Authenticate user with email and password
  /// 
  /// Attempts to log in the user with the provided credentials.
  /// On success, stores the authentication token securely and returns the user.
  /// 
  /// **Parameters:**
  /// - [email]: User's email address
  /// - [password]: User's password
  /// 
  /// **Returns:**
  /// - [Result<User>]: Success with authenticated user or failure with error
  /// 
  /// **Possible Failures:**
  /// - [NetworkFailure]: When network request fails
  /// - [AuthFailure]: When credentials are invalid
  /// - [ServerFailure]: When server returns an error
  /// - [CacheFailure]: When token storage fails
  Future<Result<User>> login({
    required String email,
    required String password,
  });

  /// Log out the current user
  /// 
  /// Clears the stored authentication token and any cached user data.
  /// This operation should always succeed locally, even if network fails.
  /// 
  /// **Returns:**
  /// - [Result<void>]: Success or failure with error details
  /// 
  /// **Possible Failures:**
  /// - [CacheFailure]: When token cleanup fails (rare)
  Future<Result<void>> logout();

  /// Get the currently stored authentication token
  /// 
  /// Retrieves the authentication token from secure storage.
  /// Returns null if no token is stored or if the token has expired.
  /// 
  /// **Returns:**
  /// - [Result<String?>]: Success with token (or null) or failure with error
  /// 
  /// **Possible Failures:**
  /// - [CacheFailure]: When token retrieval fails
  Future<Result<String?>> getStoredToken();

  /// Check if user is currently authenticated
  /// 
  /// Verifies if there's a valid authentication token stored.
  /// This is a quick check that doesn't validate the token with the server.
  /// 
  /// **Returns:**
  /// - [Result<bool>]: Success with authentication status or failure
  /// 
  /// **Possible Failures:**
  /// - [CacheFailure]: When token check fails
  Future<Result<bool>> isAuthenticated();

  /// Get the current authenticated user
  /// 
  /// Retrieves the current user information from cache or validates
  /// the stored token with the server if needed.
  /// 
  /// **Returns:**
  /// - [Result<User?>]: Success with user (or null if not authenticated) or failure
  /// 
  /// **Possible Failures:**
  /// - [CacheFailure]: When user data retrieval fails
  /// - [NetworkFailure]: When token validation fails (if network check is performed)
  /// - [AuthFailure]: When stored token is invalid
  Future<Result<User?>> getCurrentUser();

  /// Refresh the authentication token
  /// 
  /// Attempts to refresh the current authentication token using a refresh token
  /// or by re-validating with the server. This is optional functionality.
  /// 
  /// **Returns:**
  /// - [Result<User>]: Success with updated user or failure
  /// 
  /// **Possible Failures:**
  /// - [NetworkFailure]: When refresh request fails
  /// - [AuthFailure]: When refresh token is invalid
  /// - [ServerFailure]: When server returns an error
  Future<Result<User>> refreshToken();

  /// Validate the current token with the server
  /// 
  /// Checks if the stored authentication token is still valid by
  /// making a request to the server. Useful for checking token expiry.
  /// 
  /// **Returns:**
  /// - [Result<bool>]: Success with validation status or failure
  /// 
  /// **Possible Failures:**
  /// - [NetworkFailure]: When validation request fails
  /// - [AuthFailure]: When token is invalid or expired
  /// - [ServerFailure]: When server returns an error
  Future<Result<bool>> validateToken();
}