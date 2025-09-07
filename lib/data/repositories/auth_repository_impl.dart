import 'package:mini_feed/core/errors/failures.dart';
import 'package:mini_feed/core/utils/result.dart';
import 'package:mini_feed/data/datasources/local/auth_local_datasource.dart';
import 'package:mini_feed/data/datasources/remote/auth_remote_datasource.dart';
import 'package:mini_feed/domain/entities/user.dart';
import 'package:mini_feed/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Result<User>> login({
    required String email,
    required String password,
  }) async {
    try {
      final result = await remoteDataSource.login(email: email, password: password);
      await localDataSource.saveUser(result.user);
      await localDataSource.saveToken(result.token);
      return Result.success(result.user.toEntity());
    } catch (e) {
      return Result.failure(ServerFailure('Login failed', e.toString()));
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      await localDataSource.clearToken();
      await localDataSource.clearUser();
      return Result.success(null);
    } catch (e) {
      return Result.failure(CacheFailure('Logout failed', e.toString()));
    }
  }

  @override
  Future<Result<User?>> getCurrentUser() async {
    try {
      final user = await localDataSource.getUser();
      return Result.success(user?.toEntity());
    } catch (e) {
      return Result.failure(CacheFailure('Failed to get current user', e.toString()));
    }
  }

  @override
  Future<Result<bool>> isAuthenticated() async {
    try {
      final token = await localDataSource.getToken();
      return Result.success(token != null && token.isNotEmpty);
    } catch (e) {
      return Result.failure(CacheFailure('Failed to check authentication', e.toString()));
    }
  }

  @override
  Future<Result<String?>> getStoredToken() async {
    try {
      final token = await localDataSource.getToken();
      return Result.success(token);
    } catch (e) {
      return Result.failure(CacheFailure('Failed to get stored token', e.toString()));
    }
  }

  @override
  Future<Result<bool>> validateToken(String token) async {
    try {
      // For demo purposes, assume token is valid if not empty
      return Result.success(token.isNotEmpty);
    } catch (e) {
      return Result.failure(ServerFailure('Token validation failed', e.toString()));
    }
  }

  @override
  Future<Result<User>> refreshToken() async {
    try {
      final currentUser = await localDataSource.getUser();
      if (currentUser == null) {
        return Result.failure(AuthFailure('No user found', 'User not logged in'));
      }
      // For demo purposes, return current user
      return Result.success(currentUser.toEntity());
    } catch (e) {
      return Result.failure(ServerFailure('Token refresh failed', e.toString()));
    }
  }
}