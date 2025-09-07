import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../lib/core/utils/result.dart';
import '../../../../lib/core/errors/failures.dart' as failures;
import '../../../../lib/domain/entities/user.dart';
import '../../../../lib/domain/usecases/auth/login_usecase.dart';
import '../../../../lib/domain/usecases/auth/logout_usecase.dart';
import '../../../../lib/domain/usecases/auth/check_auth_status_usecase.dart';
import '../../../../lib/domain/usecases/auth/get_current_user_usecase.dart';
import '../../../../lib/presentation/blocs/auth/auth_bloc.dart';
import '../../../../lib/presentation/blocs/auth/auth_event.dart';
import '../../../../lib/presentation/blocs/auth/auth_state.dart';

// Mock classes
class MockLoginUseCase extends Mock implements LoginUseCase {}
class MockLogoutUseCase extends Mock implements LogoutUseCase {}
class MockCheckAuthStatusUseCase extends Mock implements CheckAuthStatusUseCase {}
class MockGetCurrentUserUseCase extends Mock implements GetCurrentUserUseCase {}

void main() {
  late AuthBloc authBloc;
  late MockLoginUseCase mockLoginUseCase;
  late MockLogoutUseCase mockLogoutUseCase;
  late MockCheckAuthStatusUseCase mockCheckAuthStatusUseCase;
  late MockGetCurrentUserUseCase mockGetCurrentUserUseCase;

  const testUser = User(
    id: 1,
    email: 'test@example.com',
    firstName: 'Test',
    lastName: 'User',
    token: 'test_token',
  );

  setUp(() {
    mockLoginUseCase = MockLoginUseCase();
    mockLogoutUseCase = MockLogoutUseCase();
    mockCheckAuthStatusUseCase = MockCheckAuthStatusUseCase();
    mockGetCurrentUserUseCase = MockGetCurrentUserUseCase();

    authBloc = AuthBloc(
      loginUseCase: mockLoginUseCase,
      logoutUseCase: mockLogoutUseCase,
      checkAuthStatusUseCase: mockCheckAuthStatusUseCase,
      getCurrentUserUseCase: mockGetCurrentUserUseCase,
    );

    // Register fallback values for mocktail
    registerFallbackValue(const LoginParams(email: '', password: ''));
  });

  tearDown(() {
    authBloc.close();
  });

  group('AuthBloc', () {
    test('initial state is AuthInitial', () {
      expect(authBloc.state, const AuthInitial());
    });

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthSuccess] when login is successful',
      build: () {
        when(() => mockLoginUseCase(any())).thenAnswer(
          (_) async => success(testUser),
        );
        return authBloc;
      },
      act: (bloc) => bloc.add(const AuthLoginRequested(
        email: 'test@example.com',
        password: 'password123',
      )),
      expect: () => [
        const AuthLoading(),
        const AuthSuccess(user: testUser),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthFailure] when login fails',
      build: () {
        when(() => mockLoginUseCase(any())).thenAnswer(
          (_) async => failure(const failures.AuthFailure('Invalid credentials')),
        );
        return authBloc;
      },
      act: (bloc) => bloc.add(const AuthLoginRequested(
        email: 'test@example.com',
        password: 'password123',
      )),
      expect: () => [
        const AuthLoading(),
        const AuthFailure(message: 'Invalid credentials'),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthLoggedOut] when logout is successful',
      build: () {
        when(() => mockLogoutUseCase()).thenAnswer(
          (_) async => success(null),
        );
        return authBloc;
      },
      act: (bloc) => bloc.add(const AuthLogoutRequested()),
      expect: () => [
        const AuthLoading(),
        const AuthLoggedOut(),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthSuccess] when user is authenticated',
      build: () {
        when(() => mockCheckAuthStatusUseCase()).thenAnswer(
          (_) async => success(testUser),
        );
        return authBloc;
      },
      act: (bloc) => bloc.add(const AuthStatusChecked()),
      expect: () => [
        const AuthLoading(),
        const AuthSuccess(user: testUser),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthLoggedOut] when user is not authenticated',
      build: () {
        when(() => mockCheckAuthStatusUseCase()).thenAnswer(
          (_) async => success(null),
        );
        return authBloc;
      },
      act: (bloc) => bloc.add(const AuthStatusChecked()),
      expect: () => [
        const AuthLoading(),
        const AuthLoggedOut(),
      ],
    );
  });
}