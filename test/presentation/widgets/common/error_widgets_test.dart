import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mini_feed/presentation/widgets/common/error_widgets.dart';

void main() {
  group('Error Widgets', () {
    testWidgets('AppErrorWidget should render with message', (tester) async {
      const message = 'Something went wrong';
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppErrorWidget(message: message),
          ),
        ),
      );

      expect(find.text(message), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('AppErrorWidget should show retry button when onRetry is provided', (tester) async {
      bool retryPressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppErrorWidget(
              message: 'Error',
              onRetry: () => retryPressed = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      expect(retryPressed, isTrue);
    });

    testWidgets('AppErrorWidget should show details when showDetails is true', (tester) async {
      const message = 'Error occurred';
      const details = 'Detailed error information';
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppErrorWidget(
              message: message,
              details: details,
              showDetails: true,
            ),
          ),
        ),
      );

      expect(find.text(message), findsOneWidget);
      expect(find.text(details), findsOneWidget);
    });

    testWidgets('NetworkErrorWidget should render with network-specific icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NetworkErrorWidget(),
          ),
        ),
      );

      expect(find.byIcon(Icons.wifi_off), findsOneWidget);
      expect(find.text('No internet connection'), findsOneWidget);
    });

    testWidgets('ServerErrorWidget should render with server-specific icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ServerErrorWidget(),
          ),
        ),
      );

      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
      expect(find.text('Server error'), findsOneWidget);
    });

    testWidgets('InlineErrorWidget should render with error styling', (tester) async {
      const message = 'Inline error message';
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InlineErrorWidget(message: message),
          ),
        ),
      );

      expect(find.text(message), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.byType(Container), findsOneWidget);
    });

    testWidgets('InlineErrorWidget should show retry button when onRetry is provided', (tester) async {
      bool retryPressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InlineErrorWidget(
              message: 'Error',
              onRetry: () => retryPressed = true,
            ),
          ),
        ),
      );

      expect(find.byType(TextButton), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      
      await tester.tap(find.byType(TextButton));
      expect(retryPressed, isTrue);
    });

    testWidgets('ErrorSnackBar.show should display snackbar', (tester) async {
      const message = 'Error message';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => ErrorSnackBar.show(context, message: message),
                child: const Text('Show Error'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Error'));
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text(message), findsOneWidget);
    });

    testWidgets('SuccessSnackBar.show should display success snackbar', (tester) async {
      const message = 'Success message';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => SuccessSnackBar.show(context, message: message),
                child: const Text('Show Success'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Success'));
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text(message), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });
  });
}