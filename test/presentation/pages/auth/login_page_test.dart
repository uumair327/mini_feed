import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mini_feed/presentation/blocs/auth/auth_bloc.dart';
import 'package:mini_feed/presentation/blocs/auth/auth_event.dart';
import 'package:mini_feed/presentation/blocs/auth/auth_state.dart';
import 'package:mini_feed/presentation/pages/auth/login_page.dart';

class MockAuthBloc extends Mock implements AuthBloc {
  @override
  AuthState get state => const AuthInitial();
  
  @override
  Stream<AuthState> get stream => Stream.value(const AuthInitial());
  
  @override
  void add(AuthEvent event) {}
  
  @override
  Future<void> close() async {}
  
  @override
  bool get isClosed => false;
}

void main() {
  group('LoginPage', () {
    late MockAuthBloc mockAuthBloc;

    setUp(() {
      mockAuthBloc = MockAuthBloc();
    });

    Widget createWidgetUnderTest() {
      return MaterialApp(
        home: BlocProvider<AuthBloc>(
          create: (_) => mockAuthBloc,
          child: const LoginPage(),
        ),
      );
    }

    testWidgets('should display login form with email and password fields', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthInitial());

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Mini Feed'), findsOneWidget);
      expect(find.text('Sign in to continue'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
    });

    testWidgets('should display demo credentials card', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthInitial());

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Demo Credentials'), findsOneWidget);
      expect(find.text('eve.holt@reqres.in'), findsOneWidget);
      expect(find.text('cityslicka'), findsOneWidget);
      expect(find.text('Use Demo Credentials'), findsOneWidget);
    });

    testWidgets('should fill demo credentials when button is tapped', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthInitial());

      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.text('Use Demo Credentials'));
      await tester.pump();

      final emailField = tester.widget<TextFormField>(
        find.byType(TextFormField).first,
      );
      final passwordField = tester.widget<TextFormField>(
        find.byType(TextFormField).last,
      );

      expect(emailField.controller?.text, equals('eve.holt@reqres.in'));
      expect(passwordField.controller?.text, equals('cityslicka'));
    });

    testWidgets('should validate email field', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthInitial());

      await tester.pumpWidget(createWidgetUnderTest());

      // Try to submit with empty email
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Email is required'), findsOneWidget);

      // Enter invalid email
      await tester.enterText(find.byType(TextFormField).first, 'invalid-email');
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Please enter a valid email address'), findsOneWidget);
    });

    testWidgets('should validate password field', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthInitial());

      await tester.pumpWidget(createWidgetUnderTest());

      // Enter valid email but no password
      await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Password is required'), findsOneWidget);

      // Enter short password
      await tester.enterText(find.byType(TextFormField).last, '123');
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Password must be at least 6 characters'), findsOneWidget);
    });

    testWidgets('should trigger login event when form is valid', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthInitial());

      await tester.pumpWidget(createWidgetUnderTest());

      await tester.enterText(find.byType(TextFormField).first, 'eve.holt@reqres.in');
      await tester.enterText(find.byType(TextFormField).last, 'cityslicka');
      
      await tester.tap(find.text('Sign In'));
      await tester.pump();

      verify(() => mockAuthBloc.add(
        const AuthLoginRequested(
          email: 'eve.holt@reqres.in',
          password: 'cityslicka',
        ),
      )).called(1);
    });

    testWidgets('should show loading state when authentication is in progress', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthLoading());

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should toggle password visibility', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthInitial());

      await tester.pumpWidget(createWidgetUnderTest());

      final visibilityToggle = find.byIcon(Icons.visibility);
      expect(visibilityToggle, findsOneWidget);

      // Tap visibility toggle
      await tester.tap(visibilityToggle);
      await tester.pump();

      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
    });
  });
}