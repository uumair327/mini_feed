import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mini_feed/core/utils/logger.dart';
import 'package:mini_feed/core/utils/result.dart';
import 'package:mini_feed/domain/usecases/auth/check_auth_status_usecase.dart';
import 'package:mini_feed/domain/usecases/auth/get_current_user_usecase.dart';
import 'package:mini_feed/domain/usecases/auth/login_usecase.dart';
import 'package:mini_feed/domain/usecases/auth/logout_usecase.dart';
import 'package:mini_feed/presentation/blocs/auth/auth_event.dart';
import 'package:mini_feed/presentation/blocs/auth/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final LogoutUseCase logoutUseCase;
  final CheckAuthStatusUseCase checkAuthStatusUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;

  AuthBloc({
    required this.loginUseCase,
    required this.logoutUseCase,
    required this.checkAuthStatusUseCase,
    required this.getCurrentUserUseCase,
  }) : super(const AuthInitial()) {
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthStatusChecked>(_onAuthStatusChecked);
    on<AuthTokenRefreshRequested>(_onTokenRefreshRequested);
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    
    try {
      Logger.info('Attempting login for email: ${event.email}');
      
      final result = await loginUseCase(LoginParams(
        email: event.email,
        password: event.password,
      ));

      if (result.isSuccess) {
        final user = result.successValue!;
        Logger.info('Login successful for user: ${user.email}');
        emit(AuthSuccess(user: user));
      } else {
        final failure = result.failureValue!;
        Logger.error('Login failed: ${failure.message}');
        emit(AuthFailure(
          message: failure.message,
        ));
      }
    } catch (e) {
      Logger.error('Unexpected error during login', e);
      emit(const AuthFailure(
        message: 'An unexpected error occurred during login',
      ));
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    
    try {
      Logger.info('Attempting logout');
      
      final result = await logoutUseCase();

      if (result.isSuccess) {
        Logger.info('Logout successful');
        emit(const AuthLoggedOut());
      } else {
        final failure = result.failureValue!;
        Logger.error('Logout failed: ${failure.message}');
        // Even if logout fails, we should still log out locally
        emit(const AuthLoggedOut());
      }
    } catch (e) {
      Logger.error('Unexpected error during logout', e);
      // Even if there's an error, we should still log out locally
      emit(const AuthLoggedOut());
    }
  }

  Future<void> _onAuthStatusChecked(
    AuthStatusChecked event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    
    try {
      Logger.info('Checking authentication status');
      
      final result = await checkAuthStatusUseCase();

      if (result.isSuccess) {
        final user = result.successValue;
        if (user != null) {
          Logger.info('User is authenticated: ${user.email}');
          emit(AuthSuccess(user: user));
        } else {
          Logger.info('User is not authenticated');
          emit(const AuthLoggedOut());
        }
      } else {
        final failure = result.failureValue!;
        Logger.error('Auth status check failed: ${failure.message}');
        emit(const AuthLoggedOut());
      }
    } catch (e) {
      Logger.error('Unexpected error during auth status check', e);
      emit(const AuthLoggedOut());
    }
  }

  Future<void> _onTokenRefreshRequested(
    AuthTokenRefreshRequested event,
    Emitter<AuthState> emit,
  ) async {
    try {
      Logger.info('Attempting token refresh');
      
      final result = await getCurrentUserUseCase();

      if (result.isSuccess) {
        final user = result.successValue;
        if (user != null) {
          Logger.info('Token refresh successful for user: ${user.email}');
          emit(AuthSuccess(user: user));
        } else {
          Logger.info('No user found during token refresh');
          emit(const AuthLoggedOut());
        }
      } else {
        final failure = result.failureValue!;
        Logger.error('Token refresh failed: ${failure.message}');
        emit(const AuthLoggedOut());
      }
    } catch (e) {
      Logger.error('Unexpected error during token refresh', e);
      emit(const AuthLoggedOut());
    }
  }
}