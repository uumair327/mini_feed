import 'package:dio/dio.dart';
import '../../../core/network/network_client.dart';
import '../../../core/utils/result.dart';
import '../../../core/errors/exceptions.dart';
import '../../models/login_response_model.dart';
import '../../models/user_model.dart';

/// Remote data source for authentication operations
/// 
/// Handles authentication API calls to reqres.in for login functionality.
/// Provides mock authentication for development and testing purposes.
abstract class AuthRemoteDataSource {
  /// Login with email and password
  Future<Result<LoginResponseModel>> login({
    required String email,
    required String password,
  });

  /// Get user profile by ID
  Future<Result<UserModel>> getUserProfile(int userId);

  /// Register a new user (mock implementation)
  Future<Result<LoginResponseModel>> register({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  });
}

/// Implementation of AuthRemoteDataSource using reqres.in API
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final NetworkClient networkClient;

  const AuthRemoteDataSourceImpl(this.networkClient);

  @override
  Future<Result<LoginResponseModel>> login({
    required String email,
    required String password,
  }) async {
    try {
      // Call reqres.in login endpoint
      final response = await networkClient.post(
        '/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      // Extract token from response
      final token = response.data['token'] as String;

      // Get user profile using the email (reqres.in doesn't return user data in login)
      final userResult = await _getUserByEmail(email);
      if (userResult.isFailure) {
        return failure(userResult.failureValue!);
      }

      // Create login response with user data and token
      final loginResponse = LoginResponseModel(
        user: userResult.successValue!,
        token: token,
        refreshToken: null, // reqres.in doesn't provide refresh tokens
        expiresIn: 3600, // Default 1 hour expiration
        tokenType: 'Bearer',
      );

      return success(loginResponse);
    } on ServerException catch (e) {
      print('[AUTH DEBUG] ServerException caught - Status: ${e.statusCode}, Message: ${e.message}, Email: $email');
      print('[AUTH DEBUG] Is demo credentials: ${_isDemoCredentials(email, password)}');
      
      // For demo purposes, if we get any error with the known demo credentials,
      // fall back to mock authentication
      if (_isDemoCredentials(email, password)) {
        print('[AUTH DEBUG] Using mock authentication fallback');
        // Fallback to mock authentication for demo purposes
        return _createMockLoginResponse(email);
      }
      
      print('[AUTH DEBUG] Not using fallback, rethrowing exception');
      rethrow;
    } on NetworkException catch (e) {
      print('[AUTH DEBUG] NetworkException caught - Message: ${e.message}, Email: $email');
      print('[AUTH DEBUG] Is demo credentials: ${_isDemoCredentials(email, password)}');
      
      // For demo purposes, if we get any error with the known demo credentials,
      // fall back to mock authentication
      if (_isDemoCredentials(email, password)) {
        print('[AUTH DEBUG] Using mock authentication fallback for network error');
        // Fallback to mock authentication for demo purposes
        return _createMockLoginResponse(email);
      }
      
      rethrow;
    } catch (e) {
      print('[AUTH DEBUG] Generic exception caught: $e, Email: $email');
      
      // For demo purposes, if we get any error with the known demo credentials,
      // fall back to mock authentication
      if (_isDemoCredentials(email, password)) {
        print('[AUTH DEBUG] Using mock authentication fallback for generic error');
        // Fallback to mock authentication for demo purposes
        return _createMockLoginResponse(email);
      }
      
      throw ServerException('Unexpected error during login: $e', 500);
    }
  }

  @override
  Future<Result<UserModel>> getUserProfile(int userId) async {
    try {
      final response = await networkClient.get('/users/$userId');
      
      final userData = response.data['data'] as Map<String, dynamic>;
      final user = UserModel.fromReqresJson(userData);
      
      return success(user);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw const ServerException('User not found', 404);
      } else {
        throw ServerException(
          'Failed to get user profile: ${e.message}',
          e.response?.statusCode ?? 500,
        );
      }
    } catch (e) {
      throw ServerException('Unexpected error getting user profile: $e', 500);
    }
  }

  @override
  Future<Result<LoginResponseModel>> register({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    try {
      // Call reqres.in register endpoint
      final response = await networkClient.post(
        '/register',
        data: {
          'email': email,
          'password': password,
        },
      );

      // Extract token from response
      final token = response.data['token'] as String;
      final userId = response.data['id'] as int;

      // Create a mock user with the provided information
      final user = UserModel(
        id: userId,
        email: email,
        firstName: firstName,
        lastName: lastName,
        token: token,
      );

      // Create login response
      final loginResponse = LoginResponseModel(
        user: user,
        token: token,
        refreshToken: null,
        expiresIn: 3600,
        tokenType: 'Bearer',
      );

      return success(loginResponse);
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw const ServerException('Registration failed - invalid data', 400);
      } else {
        throw ServerException(
          'Registration failed: ${e.message}',
          e.response?.statusCode ?? 500,
        );
      }
    } catch (e) {
      throw ServerException('Unexpected error during registration: $e', 500);
    }
  }

  /// Helper method to get user by email
  /// Since reqres.in doesn't have a direct email lookup, we'll use a known user
  Future<Result<UserModel>> _getUserByEmail(String email) async {
    try {
      // For demo purposes, we'll map common test emails to user IDs
      // In a real app, this would be handled by the backend
      int userId;
      switch (email.toLowerCase()) {
        case 'eve.holt@reqres.in':
          userId = 4;
          break;
        case 'janet.weaver@reqres.in':
          userId = 2;
          break;
        case 'emma.wong@reqres.in':
          userId = 3;
          break;
        default:
          // Default to user 1 for any other email
          userId = 1;
      }

      return await getUserProfile(userId);
    } catch (e) {
      throw ServerException('Failed to get user by email: $e', 500);
    }
  }

  /// Check if the provided credentials are the known demo credentials
  bool _isDemoCredentials(String email, String password) {
    final result = email.toLowerCase() == 'eve.holt@reqres.in' && password == 'cityslicka';
    print('[AUTH DEBUG] Demo credentials check - Email: $email, Password: $password, Result: $result');
    return result;
  }

  /// Create a mock login response for demo purposes when API is unavailable
  Future<Result<LoginResponseModel>> _createMockLoginResponse(String email) async {
    try {
      print('[AUTH DEBUG] Creating mock login response for: $email');
      
      // Create a mock user based on the email
      final user = UserModel(
        id: 4,
        email: email,
        firstName: 'Eve',
        lastName: 'Holt',
        token: 'demo_token_${DateTime.now().millisecondsSinceEpoch}',
      );

      // Create login response
      final loginResponse = LoginResponseModel(
        user: user,
        token: user.token!,
        refreshToken: null,
        expiresIn: 3600,
        tokenType: 'Bearer',
      );

      print('[AUTH DEBUG] Mock login response created successfully');
      return success(loginResponse);
    } catch (e) {
      print('[AUTH DEBUG] Error creating mock response: $e');
      throw ServerException('Failed to create mock login response: $e', 500);
    }
  }

  /// Handle API errors and convert to appropriate exceptions
  Never _handleApiError(DioException error) {
    final statusCode = error.response?.statusCode ?? 500;
    final message = error.response?.data?['error'] ?? error.message ?? 'Unknown error';
    
    if (statusCode >= 500) {
      throw ServerException('Server error: $message', statusCode);
    } else if (statusCode == 404) {
      throw const ServerException('Resource not found', 404);
    } else if (statusCode == 401) {
      throw const ServerException('Unauthorized', 401);
    } else if (statusCode == 400) {
      throw ServerException('Bad request: $message', 400);
    } else {
      throw ServerException('API error: $message', statusCode);
    }
  }
}