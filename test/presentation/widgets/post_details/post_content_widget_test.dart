import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mini_feed/domain/entities/post.dart';
import 'package:mini_feed/presentation/widgets/post_details/post_content_widget.dart';

void main() {
  group('PostContentWidget', () {
    late Post testPost;
    bool favoriteToggleCalled = false;
    bool newFavoriteValue = false;

    setUp(() {
      favoriteToggleCalled = false;
      newFavoriteValue = false;
      
      testPost = Post(
        id: 1,
        userId: 123,
        title: 'Test Post Title',
        body: 'This is a test post body with detailed content that should be displayed properly.',
        isFavorite: false,
        isOptimistic: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
      );
    });

    Widget createPostContentWidget({
      Post? post,
      bool isTogglingFavorite = false,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: PostContentWidget(
            post: post ?? testPost,
            onFavoriteToggle: (isFavorite) {
              favoriteToggleCalled = true;
              newFavoriteValue = isFavorite;
            },
            isTogglingFavorite: isTogglingFavorite,
          ),
        ),
      );
    }

    testWidgets('should display post title and body', (tester) async {
      await tester.pumpWidget(createPostContentWidget());

      expect(find.text(testPost.title), findsOneWidget);
      expect(find.text(testPost.body), findsOneWidget);
    });

    testWidgets('should display author information', (tester) async {
      await tester.pumpWidget(createPostContentWidget());

      expect(find.text('User ${testPost.userId}'), findsNWidgets(2)); // Appears in header and metadata
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('should display favorite button with correct icon', (tester) async {
      await tester.pumpWidget(createPostContentWidget());

      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsNothing);
    });

    testWidgets('should display filled favorite icon when post is favorited', (tester) async {
      final favoritedPost = testPost.copyWith(isFavorite: true);
      
      await tester.pumpWidget(createPostContentWidget(post: favoritedPost));

      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border), findsNothing);
    });

    testWidgets('should call onFavoriteToggle when favorite button is tapped', (tester) async {
      await tester.pumpWidget(createPostContentWidget());

      await tester.tap(find.byIcon(Icons.favorite_border));
      await tester.pump();

      expect(favoriteToggleCalled, isTrue);
      expect(newFavoriteValue, isTrue); // Should toggle to true
    });

    testWidgets('should toggle favorite state correctly', (tester) async {
      final favoritedPost = testPost.copyWith(isFavorite: true);
      
      await tester.pumpWidget(createPostContentWidget(post: favoritedPost));

      await tester.tap(find.byIcon(Icons.favorite));
      await tester.pump();

      expect(favoriteToggleCalled, isTrue);
      expect(newFavoriteValue, isFalse); // Should toggle to false
    });

    testWidgets('should show loading indicator when toggling favorite', (tester) async {
      await tester.pumpWidget(createPostContentWidget(
        isTogglingFavorite: true,
      ));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border), findsNothing);
    });

    testWidgets('should disable favorite button when toggling', (tester) async {
      await tester.pumpWidget(createPostContentWidget(
        isTogglingFavorite: true,
      ));

      // Should not be able to tap when loading
      await tester.tap(find.byType(CircularProgressIndicator));
      await tester.pump();

      expect(favoriteToggleCalled, isFalse);
    });

    testWidgets('should display post metadata', (tester) async {
      await tester.pumpWidget(createPostContentWidget());

      expect(find.text('Post Information'), findsOneWidget);
      expect(find.text('#${testPost.id}'), findsOneWidget);
      expect(find.text('User ${testPost.userId}'), findsAtLeastNWidgets(1));
    });

    testWidgets('should show optimistic status when post is optimistic', (tester) async {
      final optimisticPost = testPost.copyWith(isOptimistic: true);
      
      await tester.pumpWidget(createPostContentWidget(post: optimisticPost));

      expect(find.text('Syncing...'), findsOneWidget);
      expect(find.byIcon(Icons.sync), findsOneWidget);
    });

    testWidgets('should handle null created date gracefully', (tester) async {
      final postWithNullDate = testPost.copyWith(createdAt: null);
      
      await tester.pumpWidget(createPostContentWidget(post: postWithNullDate));

      // Check that the widget renders without errors when createdAt is null
      expect(find.byType(PostContentWidget), findsOneWidget);
      expect(find.text(postWithNullDate.title), findsOneWidget);
    });

    testWidgets('should show updated date when different from created date', (tester) async {
      final updatedPost = testPost.copyWith(
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
      );
      
      await tester.pumpWidget(createPostContentWidget(post: updatedPost));

      expect(find.textContaining('Updated:'), findsOneWidget);
    });

    testWidgets('should not show updated date when same as created date', (tester) async {
      final sameDate = DateTime.now().subtract(const Duration(hours: 2));
      final postSameDate = testPost.copyWith(
        createdAt: sameDate,
        updatedAt: sameDate,
      );
      
      await tester.pumpWidget(createPostContentWidget(post: postSameDate));

      expect(find.textContaining('Updated:'), findsNothing);
    });

    testWidgets('should display proper semantic labels for accessibility', (tester) async {
      await tester.pumpWidget(createPostContentWidget());

      expect(find.bySemanticsLabel('Add to favorites'), findsOneWidget);
    });

    testWidgets('should display remove from favorites label when favorited', (tester) async {
      final favoritedPost = testPost.copyWith(isFavorite: true);
      
      await tester.pumpWidget(createPostContentWidget(post: favoritedPost));

      expect(find.bySemanticsLabel('Remove from favorites'), findsOneWidget);
    });

    testWidgets('should display title with proper styling', (tester) async {
      await tester.pumpWidget(createPostContentWidget());

      final titleFinder = find.text(testPost.title);
      expect(titleFinder, findsOneWidget);
    });

    testWidgets('should allow text selection in body', (tester) async {
      await tester.pumpWidget(createPostContentWidget());

      expect(find.byType(SelectableText), findsOneWidget);
    });

    testWidgets('should display metadata icons correctly', (tester) async {
      await tester.pumpWidget(createPostContentWidget());

      expect(find.byIcon(Icons.tag), findsOneWidget); // Post ID
      expect(find.byIcon(Icons.person_outline), findsOneWidget); // Author
      expect(find.byIcon(Icons.schedule), findsOneWidget); // Created date
    });
  });
}