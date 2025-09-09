import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mini_feed/presentation/widgets/common/comprehensive_error_widget.dart';
import 'package:mini_feed/core/errors/failures.dart';

void main() {
  group('ComprehensiveErrorWidget', () {
    testWidgets('should display error message and retry button', (tester) async {
      bool retryPressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ComprehensiveErrorWidget(
              message: 'Test error message',
              onRetry: () => retryPressed = true,
            ),
          ),
        ),
      );

      // Verify error message is displayed
      expect(find.text('Test error message'), findsOneWidget);
      
      // Verify retry button is displayed
      expect(find.text('Try Again'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
      
      // Tap retry button
      await tester.tap(find.text('Try Again'));
      await tester.pump();
      
      // Verify retry callback was called
      expect(retryPressed, isTrue);
    });

    testWidgets('should not show retry button when canRetry is false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ComprehensiveErrorWidget(
              message: 'Test error message',
              canRetry: false,
              onRetry: () {},
            ),
          ),
        ),
      );

      // Verify error message is displayed
      expect(find.text('Test error message'), findsOneWidget);
      
      // Verify retry button is not displayed
      expect(find.text('Try Again'), findsNothing);
    });

    testWidgets('should show custom action button when provided', (tester) async {
      bool actionPressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ComprehensiveErrorWidget(
              message: 'Test error message',
              actionLabel: 'Custom Action',
              onAction: () => actionPressed = true,
            ),
          ),
        ),
      );

      // Verify custom action button is displayed
      expect(find.text('Custom Action'), findsOneWidget);
      
      // Tap custom action button
      await tester.tap(find.text('Custom Action'));
      await tester.pump();
      
      // Verify action callback was called
      expect(actionPressed, isTrue);
    });

    testWidgets('should show technical details when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ComprehensiveErrorWidget(
              message: 'Test error message',
              details: 'Technical error details',
            ),
          ),
        ),
      );

      // Verify technical details expansion tile is shown
      expect(find.text('Technical Details'), findsOneWidget);
      
      // Tap to expand details
      await tester.tap(find.text('Technical Details'));
      await tester.pumpAndSettle();
      
      // Verify details are shown
      expect(find.text('Technical error details'), findsOneWidget);
    });

    group('fromFailure factory', () {
      testWidgets('should create widget from NetworkFailure', (tester) async {
        const failure = NetworkFailure(
          message: 'Network error',
          code: 'NO_INTERNET',
        );
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ComprehensiveErrorWidget.fromFailure(failure),
            ),
          ),
        );

        // Verify appropriate message is displayed
        expect(find.textContaining('No internet connection'), findsOneWidget);
        
        // Verify appropriate icon is displayed
        expect(find.byIcon(Icons.wifi_off), findsOneWidget);
      });

      testWidgets('should create widget from AuthFailure', (tester) async {
        const failure = AuthFailure(
          message: 'Auth error',
          code: 'INVALID_CREDENTIALS',
        );
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ComprehensiveErrorWidget.fromFailure(failure),
            ),
          ),
        );

        // Verify appropriate message is displayed
        expect(find.textContaining('Invalid email or password'), findsOneWidget);
        
        // Verify appropriate icon is displayed
        expect(find.byIcon(Icons.person_off), findsOneWidget);
      });

      testWidgets('should handle non-retryable failures', (tester) async {
        const failure = NetworkFailure(
          message: 'Forbidden',
          code: 'FORBIDDEN',
        );
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ComprehensiveErrorWidget.fromFailure(failure),
            ),
          ),
        );

        // Verify retry button is not shown for non-retryable errors
        expect(find.text('Try Again'), findsNothing);
      });
    });
  });

  group('CompactErrorWidget', () {
    testWidgets('should display compact error message and retry button', (tester) async {
      bool retryPressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactErrorWidget(
              message: 'Compact error message',
              onRetry: () => retryPressed = true,
            ),
          ),
        ),
      );

      // Verify error message is displayed
      expect(find.text('Compact error message'), findsOneWidget);
      
      // Verify retry button is displayed
      expect(find.text('Retry'), findsOneWidget);
      
      // Verify error icon is displayed
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      
      // Tap retry button
      await tester.tap(find.text('Retry'));
      await tester.pump();
      
      // Verify retry callback was called
      expect(retryPressed, isTrue);
    });

    testWidgets('should not show retry button when canRetry is false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactErrorWidget(
              message: 'Compact error message',
              canRetry: false,
              onRetry: () {},
            ),
          ),
        ),
      );

      // Verify error message is displayed
      expect(find.text('Compact error message'), findsOneWidget);
      
      // Verify retry button is not displayed
      expect(find.text('Retry'), findsNothing);
    });
  });

  group('ErrorSnackBar', () {
    testWidgets('should show error snackbar with message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => ErrorSnackBar.show(
                  context,
                  'Test error message',
                ),
                child: const Text('Show Error'),
              ),
            ),
          ),
        ),
      );

      // Tap button to show snackbar
      await tester.tap(find.text('Show Error'));
      await tester.pump();

      // Verify snackbar is displayed
      expect(find.text('Test error message'), findsOneWidget);
    });

    testWidgets('should show error snackbar with retry action', (tester) async {
      bool retryPressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => ErrorSnackBar.show(
                  context,
                  'Test error message',
                  onRetry: () => retryPressed = true,
                ),
                child: const Text('Show Error'),
              ),
            ),
          ),
        ),
      );

      // Tap button to show snackbar
      await tester.tap(find.text('Show Error'));
      await tester.pump();

      // Verify snackbar and retry action are displayed
      expect(find.text('Test error message'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      
      // Tap retry action
      await tester.tap(find.text('Retry'));
      await tester.pump();
      
      // Verify retry callback was called
      expect(retryPressed, isTrue);
    });

    testWidgets('should show error snackbar from failure', (tester) async {
      const failure = NetworkFailure(
        message: 'Network error',
        code: 'TIMEOUT',
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => ErrorSnackBar.showFromFailure(
                  context,
                  failure,
                ),
                child: const Text('Show Error'),
              ),
            ),
          ),
        ),
      );

      // Tap button to show snackbar
      await tester.tap(find.text('Show Error'));
      await tester.pump();

      // Verify appropriate message is displayed
      expect(find.textContaining('Request timed out'), findsOneWidget);
    });
  });
}