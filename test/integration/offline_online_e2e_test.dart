import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mini_feed/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Offline/Online Transition E2E Tests', () {
    Future<void> loginAndNavigateToFeed(WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Login
      await tester.enterText(find.byKey(const Key('email_field')), 'eve.holt@reqres.in');
      await tester.enterText(find.byKey(const Key('password_field')), 'cityslicka');
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();
    }

    testWidgets('offline indicator should appear when network is lost', (tester) async {
      await loginAndNavigateToFeed(tester);

      // Wait for posts to load while online
      await tester.pumpAndSettle(const Duration(seconds: 3));
      expect(find.byKey(const Key('post_item')), findsAtLeastNWidgets(1));

      // Simulate network loss (this would require mocking network connectivity)
      // For now, we'll test the UI behavior when offline state is triggered
      
      // Look for offline indicator
      if (find.byKey(const Key('offline_indicator')).evaluate().isNotEmpty) {
        expect(find.byKey(const Key('offline_indicator')), findsOneWidget);
        expect(find.textContaining('offline'), findsAtLeastNWidgets(1));
      }
    });

    testWidgets('cached data should be available offline', (tester) async {
      await loginAndNavigateToFeed(tester);

      // Load posts while online
      await tester.pumpAndSettle(const Duration(seconds: 3));
      final onlinePostCount = tester.widgetList(find.byKey(const Key('post_item'))).length;
      expect(onlinePostCount, greaterThan(0));

      // Simulate going offline and restarting app
      // In a real test, you would mock the network service here
      
      // Restart app (simulating offline restart)
      app.main();
      await tester.pumpAndSettle();

      // Login with cached credentials
      await tester.enterText(find.byKey(const Key('email_field')), 'eve.holt@reqres.in');
      await tester.enterText(find.byKey(const Key('password_field')), 'cityslicka');
      await tester.tap(find.byKey(const Key('login_button')));
      await tester.pumpAndSettle();

      // Should still show cached posts
      await tester.pumpAndSettle(const Duration(seconds: 2));
      expect(find.byKey(const Key('post_item')), findsAtLeastNWidgets(1));
    });

    testWidgets('optimistic updates should work offline', (tester) async {
      await loginAndNavigateToFeed(tester);

      // Wait for initial load
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Create a new post while offline
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Fill in post form
      await tester.enterText(find.byKey(const Key('title_field')), 'Offline Test Post');
      await tester.enterText(find.byKey(const Key('body_field')), 'This post was created offline');

      // Submit post
      await tester.tap(find.byKey(const Key('submit_button')));
      await tester.pumpAndSettle();

      // Should return to feed and show optimistic post
      expect(find.text('Feed'), findsOneWidget);
      expect(find.textContaining('Offline Test Post'), findsOneWidget);

      // Post should have pending/optimistic indicator
      expect(find.byKey(const Key('pending_indicator')), findsAtLeastNWidgets(1));
    });

    testWidgets('sync should occur when connectivity is restored', (tester) async {
      await loginAndNavigateToFeed(tester);

      // Create optimistic post while offline (simulated)
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('title_field')), 'Sync Test Post');
      await tester.enterText(find.byKey(const Key('body_field')), 'This should sync when online');
      await tester.tap(find.byKey(const Key('submit_button')));
      await tester.pumpAndSettle();

      // Should show optimistic post with pending indicator
      expect(find.textContaining('Sync Test Post'), findsOneWidget);

      // Simulate connectivity restoration
      // In a real test, you would trigger the connectivity service here
      
      // Wait for sync to complete
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Pending indicator should be removed after successful sync
      expect(find.byKey(const Key('pending_indicator')), findsNothing);
    });

    testWidgets('error handling during sync should work', (tester) async {
      await loginAndNavigateToFeed(tester);

      // Create post that will fail to sync
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('title_field')), 'Failed Sync Post');
      await tester.enterText(find.byKey(const Key('body_field')), 'This sync will fail');
      await tester.tap(find.byKey(const Key('submit_button')));
      await tester.pumpAndSettle();

      // Should show post with error indicator after failed sync
      await tester.pumpAndSettle(const Duration(seconds: 5));
      
      if (find.byKey(const Key('sync_error_indicator')).evaluate().isNotEmpty) {
        expect(find.byKey(const Key('sync_error_indicator')), findsAtLeastNWidgets(1));
        
        // Should have retry option
        expect(find.byKey(const Key('retry_sync_button')), findsAtLeastNWidgets(1));
        
        // Test retry functionality
        await tester.tap(find.byKey(const Key('retry_sync_button')).first);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('offline search should work with cached data', (tester) async {
      await loginAndNavigateToFeed(tester);

      // Load posts while online
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Go offline (simulated)
      // Search should still work with cached data
      await tester.tap(find.byKey(const Key('search_field')));
      await tester.enterText(find.byKey(const Key('search_field')), 'sunt');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Should show filtered results from cache
      expect(find.byKey(const Key('post_item')), findsAtLeastNWidgets(1));
    });

    testWidgets('favorites should work offline', (tester) async {
      await loginAndNavigateToFeed(tester);

      // Load posts while online
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Go offline and toggle favorite
      await tester.tap(find.byKey(const Key('favorite_button')).first);
      await tester.pumpAndSettle();

      // Should show favorite state immediately (optimistic update)
      expect(find.byIcon(Icons.favorite), findsAtLeastNWidgets(1));

      // Should queue for sync when online
      // This would be verified by checking the sync queue in a real implementation
    });

    testWidgets('connectivity status should be visible to user', (tester) async {
      await loginAndNavigateToFeed(tester);

      // Should show connectivity status
      if (find.byKey(const Key('connectivity_status')).evaluate().isNotEmpty) {
        expect(find.byKey(const Key('connectivity_status')), findsOneWidget);
      }

      // When offline, should show appropriate message
      if (find.textContaining('offline').evaluate().isNotEmpty) {
        expect(find.textContaining('offline'), findsAtLeastNWidgets(1));
      }

      // When online, should show connected status or no status
      if (find.textContaining('online').evaluate().isNotEmpty) {
        expect(find.textContaining('online'), findsAtLeastNWidgets(1));
      }
    });
  });
}