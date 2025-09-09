import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mini_feed/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Flow E2E Tests', () {
    testWidgets('complete login flow should work end-to-end', (tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Should start on login page
      expect(find.text('Login'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2)); // Email and password fields

      // Enter valid credentials
      await tester.enterText(find.byKey(const Key('email_field')), 'eve.holt@reqres.in');
      await tester.enterText(find.byKey(const Key('password_field')), 'cityslicka');

      // Tap login button
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      // Should navigate to feed page after successful login
      expect(find.text('Feed'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget); // FAB for creating posts
    });

    testWidgets('login with invalid credentials should show error', (tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Enter invalid credentials
      await tester.enterText(find.byKey(const Key('email_field')), 'invalid@email.com');
      await tester.enterText(find.byKey(const Key('password_field')), 'wrongpassword');

      // Tap login button
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      // Should show error message and stay on login page
      expect(find.textContaining('error'), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('logout flow should work correctly', (tester) async {
      // Start the app and login first
      app.main();
      await tester.pumpAndSettle();

      // Login
      await tester.enterText(find.byKey(const Key('email_field')), 'eve.holt@reqres.in');
      await tester.enterText(find.byKey(const Key('password_field')), 'cityslicka');
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      // Should be on feed page
      expect(find.text('Feed'), findsOneWidget);

      // Open app drawer or menu
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Tap logout
      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      // Should return to login page
      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('form validation should work correctly', (tester) async {
      // Start the app
      app.main();
      await tester.pumpAndSettle();

      // Try to login with empty fields
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      // Should show validation errors
      expect(find.textContaining('required'), findsAtLeastNWidgets(1));

      // Enter invalid email format
      await tester.enterText(find.byKey(const Key('email_field')), 'invalid-email');
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      // Should show email validation error
      expect(find.textContaining('valid email'), findsOneWidget);
    });

    testWidgets('auto-login should work on app restart', (tester) async {
      // First, login successfully
      app.main();
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('email_field')), 'eve.holt@reqres.in');
      await tester.enterText(find.byKey(const Key('password_field')), 'cityslicka');
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      // Verify we're on feed page
      expect(find.text('Feed'), findsOneWidget);

      // Restart the app (simulate app restart)
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/platform',
        null,
        (data) {},
      );

      // Start app again
      app.main();
      await tester.pumpAndSettle();

      // Should automatically navigate to feed page (auto-login)
      expect(find.text('Feed'), findsOneWidget);
    });
  });
}