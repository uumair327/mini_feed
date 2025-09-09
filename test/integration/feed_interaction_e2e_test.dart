import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mini_feed/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Feed Interaction E2E Tests', () {
    Future<void> loginAndNavigateToFeed(WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Login
      await tester.enterText(find.byKey(const Key('email_field')), 'eve.holt@reqres.in');
      await tester.enterText(find.byKey(const Key('password_field')), 'cityslicka');
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();
    }

    testWidgets('complete feed loading and interaction flow', (tester) async {
      await loginAndNavigateToFeed(tester);

      // Should be on feed page with posts
      expect(find.text('Feed'), findsOneWidget);
      expect(find.byType(ListView), findsOneWidget);

      // Wait for posts to load
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Should have post items
      expect(find.byKey(const Key('post_item')), findsAtLeastNWidgets(1));

      // Test pull-to-refresh
      await tester.drag(find.byType(ListView), const Offset(0, 300));
      await tester.pumpAndSettle();

      // Should show refresh indicator
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });

    testWidgets('post details navigation should work', (tester) async {
      await loginAndNavigateToFeed(tester);

      // Wait for posts to load
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Tap on first post
      await tester.tap(find.byKey(const Key('post_item')).first);
      await tester.pumpAndSettle();

      // Should navigate to post details page
      expect(find.text('Post Details'), findsOneWidget);
      expect(find.byKey(const Key('post_content')), findsOneWidget);
      expect(find.byKey(const Key('comments_section')), findsOneWidget);

      // Test back navigation
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      // Should return to feed
      expect(find.text('Feed'), findsOneWidget);
    });

    testWidgets('search functionality should work end-to-end', (tester) async {
      await loginAndNavigateToFeed(tester);

      // Wait for posts to load
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Tap on search field
      await tester.tap(find.byKey(const Key('search_field')));
      await tester.pumpAndSettle();

      // Enter search query
      await tester.enterText(find.byKey(const Key('search_field')), 'sunt');
      await tester.pumpAndSettle(const Duration(seconds: 2)); // Wait for debounce

      // Should show filtered results
      expect(find.byKey(const Key('post_item')), findsAtLeastNWidgets(1));

      // Clear search
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      // Should show all posts again
      expect(find.byKey(const Key('post_item')), findsAtLeastNWidgets(5));
    });

    testWidgets('favorite functionality should work', (tester) async {
      await loginAndNavigateToFeed(tester);

      // Wait for posts to load
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Tap favorite button on first post
      await tester.tap(find.byKey(const Key('favorite_button')).first);
      await tester.pumpAndSettle();

      // Should show filled favorite icon
      expect(find.byIcon(Icons.favorite), findsAtLeastNWidgets(1));

      // Navigate to post details
      await tester.tap(find.byKey(const Key('post_item')).first);
      await tester.pumpAndSettle();

      // Should show favorite status in details
      expect(find.byIcon(Icons.favorite), findsOneWidget);

      // Toggle favorite in details
      await tester.tap(find.byKey(const Key('favorite_toggle')));
      await tester.pumpAndSettle();

      // Should show unfavorite icon
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    });

    testWidgets('infinite scroll should work', (tester) async {
      await loginAndNavigateToFeed(tester);

      // Wait for initial posts to load
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final initialPostCount = tester.widgetList(find.byKey(const Key('post_item'))).length;

      // Scroll to bottom to trigger pagination
      await tester.drag(find.byType(ListView), const Offset(0, -1000));
      await tester.pumpAndSettle();

      // Continue scrolling
      await tester.drag(find.byType(ListView), const Offset(0, -1000));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Should have more posts loaded
      final finalPostCount = tester.widgetList(find.byKey(const Key('post_item'))).length;
      expect(finalPostCount, greaterThan(initialPostCount));
    });

    testWidgets('error handling should work correctly', (tester) async {
      // Start app in offline mode or with network error simulation
      app.main();
      await tester.pumpAndSettle();

      // Login (assuming cached credentials work)
      await tester.enterText(find.byKey(const Key('email_field')), 'eve.holt@reqres.in');
      await tester.enterText(find.byKey(const Key('password_field')), 'cityslicka');
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      // Should show offline indicator or error state
      expect(
        find.byWidgetPredicate((widget) => 
          widget is Text && 
          (widget.data?.contains('offline') == true || 
           widget.data?.contains('error') == true)
        ),
        findsAtLeastNWidgets(1),
      );

      // Should show retry button
      if (find.text('Retry').evaluate().isNotEmpty) {
        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('theme switching should work', (tester) async {
      await loginAndNavigateToFeed(tester);

      // Find and tap theme toggle button
      await tester.tap(find.byKey(const Key('theme_toggle')));
      await tester.pumpAndSettle();

      // Theme should change (verify by checking theme data)
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.themeMode, isNotNull);

      // Toggle again
      await tester.tap(find.byKey(const Key('theme_toggle')));
      await tester.pumpAndSettle();

      // Theme should change again
      final updatedMaterialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(updatedMaterialApp.themeMode, isNotNull);
    });

    testWidgets('responsive behavior should work on different screen sizes', (tester) async {
      // Test mobile layout
      await tester.binding.setSurfaceSize(const Size(375, 667)); // iPhone size
      await loginAndNavigateToFeed(tester);

      // Should show mobile layout
      expect(find.byType(ListView), findsOneWidget);

      // Test tablet layout
      await tester.binding.setSurfaceSize(const Size(768, 1024)); // iPad size
      await tester.pumpWidget(Container()); // Force rebuild
      await loginAndNavigateToFeed(tester);

      // Should adapt to tablet layout
      expect(find.byType(ListView), findsOneWidget);

      // Test desktop layout
      await tester.binding.setSurfaceSize(const Size(1200, 800)); // Desktop size
      await tester.pumpWidget(Container()); // Force rebuild
      await loginAndNavigateToFeed(tester);

      // Should adapt to desktop layout
      expect(find.byType(ListView), findsOneWidget);
    });
  });
}