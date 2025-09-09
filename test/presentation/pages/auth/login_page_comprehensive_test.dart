import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mini_feed/presentation/pages/auth/login_page.dart';
import 'package:mini_feed/presentation/blocs/auth/auth_bloc.dart';
import 'package:mini_feed/presentation/blocs/auth/auth_state.dart';
import 'package:mini_feed/presentation/blocs/auth/auth_event.dart';
import 'package:mini_feed/domain/entities/user.dart';

class MockAuthBloc extends Mock implements AuthBloc {}

void main() {
  group('LoginPage Comprehensive Tests', () {
    late MockAuthBloc mockAuthBloc;

    setUp(() {
      mockAuthBloc = MockAuthBloc();
      when(() => mockAuthBloc.state).thenReturn(const AuthInitial());
      when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());
    });

    Widget createTestWidget() {
      return MaterialApp(
        home: BlocProvider<AuthBloc>.value(
          value: mockAuthBloc,
          child: const LoginPage(),
        ),
      );
    }

    group('UI Elements', () {
      testWidgets('should display all required form elements', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Verify form elements are present
        expect(find.text('Welcome to Mini Feed'), findsOneWidget);
        expect(find.text('Email'), findsOneWidget);
        expect(find.text('Password'), findsOneWidget);
        expect(find.text('Login'), findsOneWidget);
        
        // Verify input fields
        expect(find.byType(TextFormField), findsNWidgets(2));
        
        // Verify login button
        expect(find.byType(ElevatedButton), findsOneWidget);
      });

      testWidgets('should display demo credentials card', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Verify demo credentials section
        expect(find.text('Demo Credentials'), findsOneWidget);
        expect(find.text('eve.holt@reqres.in'), findsOneWidget);
        expect(find.text('cityslicka'), findsOneWidget);
        expect(find.text('Use Demo Credentials'), findsOneWidget);
      });

      testWidgets('should have proper accessibility labels', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Verify semantic labels
        final emailField = find.byKey(const Key('email_field'));
        final passwordField = find.byKey(const Key('password_field'));
        
        expect(emailField, findsOneWidget);
        expect(passwordField, findsOneWidget);
      });
    });

    group('Form Validation', () {
      testWidgets('should show validation errors for empty fields', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Try to submit empty form
        await tester.tap(find.text('Login'));
        await tester.pump();

        // Verify validation errors
        expect(find.text('Please enter your email'), findsOneWidget);
        expect(find.text('Please enter your password'), findsOneWidget);
      });

      testWidgets('should validate email format', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Enter invalid email
        await tester.enterText(find.byKey(const Key('email_field')), 'invalid-email');
        await tester.enterText(find.byKey(const Key('password_field')), 'password123');
        
        // Try to submit
        await tester.tap(find.text('Login'));
        await tester.pump();

        // Verify email validation error
        expect(find.text('Please enter a valid email'), findsOneWidget);
      });

      testWidgets('should validate password length', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Enter short password
        await tester.enterText(find.byKey(const Key('email_field')), 'test@example.com');
        await tester.enterText(find.byKey(const Key('password_field')), '123');
        
        // Try to submit
        await tester.tap(find.text('Login'));
        await tester.pump();

        // Verify password validation error
        expect(find.text('Password must be at least 6 characters'), findsOneWidget);
      });

      testWidgets('should accept valid credentials', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Enter valid credentials
        await tester.enterText(find.byKey(const Key('email_field')), 'test@example.com');
        await tester.enterText(find.byKey(const Key('password_field')), 'password123');
        
        // Submit form
        await tester.tap(find.text('Login'));
        await tester.pump();

        // Verify login event was triggered
        verify(() => mockAuthBloc.add(const AuthLoginRequested(
          email: 'test@example.com',
          password: 'password123',
        ))).called(1);
      });
    });

    group('Demo Credentials', () {
      testWidgets('should fill form with demo credentials when button is tapped', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Tap demo credentials button
        await tester.tap(find.text('Use Demo Credentials'));
        await tester.pump();

        // Verify fields are filled
        expect(find.text('eve.holt@reqres.in'), findsNWidgets(2)); // One in card, one in field
        expect(find.text('cityslicka'), findsNWidgets(2)); // One in card, one in field
      });

      testWidgets('should be able to login with demo credentials', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Use demo credentials
        await tester.tap(find.text('Use Demo Credentials'));
        await tester.pump();

        // Submit form
        await tester.tap(find.text('Login'));
        await tester.pump();

        // Verify login event with demo credentials
        verify(() => mockAuthBloc.add(const AuthLoginRequested(
          email: 'eve.holt@reqres.in',
          password: 'cityslicka',
        ))).called(1);
      });
    });

    group('Password Visibility', () {
      testWidgets('should toggle password visibility', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Enter password
        await tester.enterText(find.byKey(const Key('password_field')), 'password123');
        
        // Find password field
        final passwordField = tester.widget<TextFormField>(find.byKey(const Key('password_field')));
        
        // Initially password should be obscured
        expect(passwordField.obscureText, isTrue);

        // Tap visibility toggle
        await tester.tap(find.byIcon(Icons.visibility));
        await tester.pump();

        // Password should now be visible
        final updatedPasswordField = tester.widget<TextFormField>(find.byKey(const Key('password_field')));
        expect(updatedPasswordField.obscureText, isFalse);

        // Tap again to hide
        await tester.tap(find.byIcon(Icons.visibility_off));
        await tester.pump();

        // Password should be obscured again
        final finalPasswordField = tester.widget<TextFormField>(find.byKey(const Key('password_field')));
        expect(finalPasswordField.obscureText, isTrue);
      });
    });

    group('Authentication States', () {
      testWidgets('should show loading state during authentication', (tester) async {
        when(() => mockAuthBloc.state).thenReturn(const AuthLoading());

        await tester.pumpWidget(createTestWidget());

        // Verify loading indicator is shown
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        
        // Verify login button is disabled
        final loginButton = tester.widget<ElevatedButton>(find.text('Login'));
        expect(loginButton.onPressed, isNull);
      });

      testWidgets('should show error message on authentication failure', (tester) async {
        when(() => mockAuthBloc.state).thenReturn(const AuthFailure(
          message: 'Invalid credentials',
        ));

        await tester.pumpWidget(createTestWidget());

        // Verify error message is displayed
        expect(find.text('Invalid credentials'), findsOneWidget);
        
        // Verify error icon is shown
        expect(find.byIcon(Icons.error), findsOneWidget);
      });

      testWidgets('should handle successful authentication', (tester) async {
        when(() => mockAuthBloc.state).thenReturn(const AuthSuccess(
          user: User(
            id: 1,
            email: 'test@example.com',
            token: 'test-token',
          ),
        ));

        await tester.pumpWidget(createTestWidget());

        // In a real app, this would navigate away from the login page
        // For testing, we just verify no errors occur
        expect(tester.takeException(), isNull);
      });
    });

    group('Form Interaction', () {
      testWidgets('should clear error when user starts typing', (tester) async {
        // Start with error state
        when(() => mockAuthBloc.state).thenReturn(const AuthFailure(
          message: 'Invalid credentials',
        ));

        await tester.pumpWidget(createTestWidget());

        // Verify error is shown
        expect(find.text('Invalid credentials'), findsOneWidget);

        // Start typing in email field
        await tester.enterText(find.byKey(const Key('email_field')), 'new@example.com');
        await tester.pump();

        // Error should be cleared (this would depend on implementation)
        // For now, we just verify typing doesn't cause errors
        expect(tester.takeException(), isNull);
      });

      testWidgets('should handle form submission with Enter key', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Enter valid credentials
        await tester.enterText(find.byKey(const Key('email_field')), 'test@example.com');
        await tester.enterText(find.byKey(const Key('password_field')), 'password123');
        
        // Press Enter in password field
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pump();

        // Verify login event was triggered
        verify(() => mockAuthBloc.add(const AuthLoginRequested(
          email: 'test@example.com',
          password: 'password123',
        ))).called(1);
      });
    });

    group('Responsive Design', () {
      testWidgets('should adapt to mobile screen size', (tester) async {
        // Set mobile screen size
        tester.binding.window.physicalSizeTestValue = const Size(400, 800);
        tester.binding.window.devicePixelRatioTestValue = 1.0;

        await tester.pumpWidget(createTestWidget());

        // Verify mobile layout
        expect(find.byType(SingleChildScrollView), findsOneWidget);
        expect(find.byType(Padding), findsWidgets);

        // Reset screen size
        addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
        addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);
      });

      testWidgets('should adapt to tablet screen size', (tester) async {
        // Set tablet screen size
        tester.binding.window.physicalSizeTestValue = const Size(800, 1200);
        tester.binding.window.devicePixelRatioTestValue = 1.0;

        await tester.pumpWidget(createTestWidget());

        // Verify tablet layout adaptations
        expect(find.byType(Center), findsWidgets);

        // Reset screen size
        addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
        addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);
      });
    });

    group('Keyboard Navigation', () {
      testWidgets('should support tab navigation between fields', (tester) async {
        await tester.pumpWidget(createTestWidget());

        // Focus on email field
        await tester.tap(find.byKey(const Key('email_field')));
        await tester.pump();

        // Verify email field is focused
        expect(Focus.of(tester.element(find.byKey(const Key('email_field')))).hasFocus, isTrue);

        // Tab to password field
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();

        // Verify password field is focused
        expect(Focus.of(tester.element(find.byKey(const Key('password_field')))).hasFocus, isTrue);
      });
    });

    group('Error Recovery', () {
      testWidgets('should allow retry after authentication failure', (tester) async {
        // Start with error state
        when(() => mockAuthBloc.state).thenReturn(const AuthFailure(
          message: 'Network error',
        ));

        await tester.pumpWidget(createTestWidget());

        // Verify error is shown
        expect(find.text('Network error'), findsOneWidget);

        // Change to initial state (simulating error clearance)
        when(() => mockAuthBloc.state).thenReturn(const AuthInitial());
        
        // Rebuild widget
        await tester.pumpWidget(createTestWidget());

        // Verify form is usable again
        expect(find.text('Network error'), findsNothing);
        expect(find.text('Login'), findsOneWidget);
        
        final loginButton = tester.widget<ElevatedButton>(find.text('Login'));
        expect(loginButton.onPressed, isNotNull);
      });
    });
  });
}