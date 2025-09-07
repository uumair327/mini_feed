import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mini_feed/domain/entities/user.dart';
import 'package:mini_feed/presentation/blocs/auth/auth_bloc.dart';
import 'package:mini_feed/presentation/blocs/auth/auth_state.dart';
import 'package:mini_feed/presentation/routes/app_router.dart';
import 'package:mini_feed/presentation/pages/auth/login_page.dart';
import 'package:mini_feed/presentation/pages/feed/feed_page.dart';

class MockAuthBloc extends Mock implements AuthBloc {
  @override
  AuthState get state => const AuthInitial();
  
  @override
  Stream<AuthState> get stream => Stream.value(const AuthInitial());
  
  @override
  void add(event) {}
  
  @override
  Future<void> close() async {}
  
  @override
  bool get isClosed => false;
}

void main() {
  group('AppRouter', () {
    test('should generate login route', () {
      final route = AppRouter.generateRoute(
        const RouteSettings(name: AppRouter.loginRoute),
      );

      expect(route, isA<MaterialPageRoute>());
    });

    test('should generate feed route', () {
      final route = AppRouter.generateRoute(
        const RouteSettings(name: AppRouter.feedRoute),
      );

      expect(route, isA<MaterialPageRoute>());
    });

    test('should generate auth wrapper for unknown routes', () {
      final route = AppRouter.generateRoute(
        const RouteSettings(name: '/unknown'),
      );

      expect(route, isA<MaterialPageRoute>());
    });
  });

  group('AuthWrapper', () {
    late MockAuthBloc mockAuthBloc;

    setUp(() {
      mockAuthBloc = MockAuthBloc();
    });

    Widget createWidgetUnderTest() {
      return MaterialApp(
        home: BlocProvider<AuthBloc>(
          create: (_) => mockAuthBloc,
          child: const AuthWrapper(),
        ),
      );
    }

    testWidgets('should show loading when auth state is loading', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthLoading());

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Checking authentication...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show feed page when authenticated', (tester) async {
      const testUser = User(id: 1, email: 'test@example.com');
      when(() => mockAuthBloc.state).thenReturn(
        const AuthSuccess(user: testUser),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(FeedPage), findsOneWidget);
    });

    testWidgets('should show login page when not authenticated', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthInitial());

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('should show login page on auth failure', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(
        const AuthFailure(message: 'Auth failed'),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(LoginPage), findsOneWidget);
    });
  });
}