import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mini_feed/presentation/widgets/common/empty_state_widgets.dart';

void main() {
  group('Empty State Widgets', () {
    testWidgets('AppEmptyStateWidget should render with title', (tester) async {
      const title = 'No items found';
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppEmptyStateWidget(title: title),
          ),
        ),
      );

      expect(find.text(title), findsOneWidget);
      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
    });

    testWidgets('AppEmptyStateWidget should show subtitle when provided', (tester) async {
      const title = 'No items';
      const subtitle = 'Try again later';
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppEmptyStateWidget(
              title: title,
              subtitle: subtitle,
            ),
          ),
        ),
      );

      expect(find.text(title), findsOneWidget);
      expect(find.text(subtitle), findsOneWidget);
    });

    testWidgets('AppEmptyStateWidget should show action button when provided', (tester) async {
      bool actionPressed = false;
      const actionText = 'Refresh';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppEmptyStateWidget(
              title: 'No items',
              actionText: actionText,
              onAction: () => actionPressed = true,
            ),
          ),
        ),
      );

      expect(find.text(actionText), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
      
      await tester.tap(find.byType(ElevatedButton));
      expect(actionPressed, isTrue);
    });

    testWidgets('EmptyPostsWidget should render for normal empty state', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyPostsWidget(),
          ),
        ),
      );

      expect(find.text('No posts yet'), findsOneWidget);
      expect(find.byIcon(Icons.article_outlined), findsOneWidget);
    });

    testWidgets('EmptyPostsWidget should render for search results', (tester) async {
      const searchQuery = 'flutter';
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyPostsWidget(
              isSearchResult: true,
              searchQuery: searchQuery,
            ),
          ),
        ),
      );

      expect(find.text('No results found'), findsOneWidget);
      expect(find.byIcon(Icons.search_off), findsOneWidget);
      expect(find.textContaining(searchQuery), findsOneWidget);
    });

    testWidgets('EmptyCommentsWidget should render correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyCommentsWidget(),
          ),
        ),
      );

      expect(find.text('No comments yet'), findsOneWidget);
      expect(find.byIcon(Icons.comment_outlined), findsOneWidget);
    });

    testWidgets('EmptyFavoritesWidget should render correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyFavoritesWidget(),
          ),
        ),
      );

      expect(find.text('No favorites yet'), findsOneWidget);
      expect(find.byIcon(Icons.favorite_outline), findsOneWidget);
    });

    testWidgets('EmptyFavoritesWidget should show browse action when provided', (tester) async {
      bool browsePressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyFavoritesWidget(
              onBrowsePosts: () => browsePressed = true,
            ),
          ),
        ),
      );

      expect(find.text('Browse Posts'), findsOneWidget);
      
      await tester.tap(find.text('Browse Posts'));
      expect(browsePressed, isTrue);
    });

    testWidgets('OfflineEmptyWidget should render correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OfflineEmptyWidget(),
          ),
        ),
      );

      expect(find.text('You\'re offline'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    });

    testWidgets('CompactEmptyState should render in smaller space', (tester) async {
      const message = 'Nothing here';
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CompactEmptyState(message: message),
          ),
        ),
      );

      expect(find.text(message), findsOneWidget);
      expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
    });

    testWidgets('CompactEmptyState should show action when provided', (tester) async {
      bool actionPressed = false;
      const actionText = 'Reload';
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactEmptyState(
              message: 'Empty',
              actionText: actionText,
              onAction: () => actionPressed = true,
            ),
          ),
        ),
      );

      expect(find.text(actionText), findsOneWidget);
      
      await tester.tap(find.text(actionText));
      expect(actionPressed, isTrue);
    });

    testWidgets('RefreshableEmptyState should render with RefreshIndicator', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RefreshableEmptyState(
              title: 'No data',
              onRefresh: () async {},
            ),
          ),
        ),
      );

      expect(find.byType(RefreshIndicator), findsOneWidget);
      expect(find.text('No data'), findsOneWidget);
    });
  });
}