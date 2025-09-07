import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mini_feed/domain/entities/post.dart';
import 'package:mini_feed/presentation/widgets/feed/post_list_item.dart';

void main() {
  group('PostListItem', () {
    late Post testPost;

    setUp(() {
      testPost = Post(
        id: 1,
        title: 'Test Post Title',
        body: 'This is a test post body with some content to display in the preview.',
        userId: 123,
        isFavorite: false,
        isOptimistic: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        updatedAt: DateTime.now(),
      );
    });

    Widget createPostListItem({
      Post? post,
      VoidCallback? onTap,
      VoidCallback? onFavoriteToggle,
      VoidCallback? onShare,
      VoidCallback? onComment,
      bool showActions = true,
      bool isCompact = false,
      String? searchQuery,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: PostListItem(
            post: post ?? testPost,
            onTap: onTap ?? () {},
            onFavoriteToggle: onFavoriteToggle ?? () {},
            onShare: onShare,
            onComment: onComment,
            showActions: showActions,
            isCompact: isCompact,
            searchQuery: searchQuery,
          ),
        ),
      );
    }

    group('Basic Display', () {
      testWidgets('should display post title and body', (tester) async {
        await tester.pumpWidget(createPostListItem());

        expect(find.text('Test Post Title'), findsOneWidget);
        expect(find.text('This is a test post body with some content to display in the preview.'), findsOneWidget);
      });

      testWidgets('should display user information', (tester) async {
        await tester.pumpWidget(createPostListItem());

        expect(find.text('User 123'), findsOneWidget);
        expect(find.text('2h ago'), findsOneWidget);
      });

      testWidgets('should display user avatar with first letter of title', (tester) async {
        await tester.pumpWidget(createPostListItem());

        expect(find.text('T'), findsOneWidget); // First letter of "Test Post Title"
        expect(find.byType(CircleAvatar), findsOneWidget);
      });
    });

    group('Favorite Functionality', () {
      testWidgets('should display unfavorite icon when post is not favorite', (tester) async {
        await tester.pumpWidget(createPostListItem());

        expect(find.byIcon(Icons.favorite_border), findsOneWidget);
        expect(find.byIcon(Icons.favorite), findsNothing);
      });

      testWidgets('should display favorite icon when post is favorite', (tester) async {
        final favoritePost = testPost.copyWith(isFavorite: true);
        
        await tester.pumpWidget(createPostListItem(post: favoritePost));

        expect(find.byIcon(Icons.favorite), findsOneWidget);
        expect(find.byIcon(Icons.favorite_border), findsNothing);
      });

      testWidgets('should call onFavoriteToggle when favorite button is tapped', (tester) async {
        bool favoriteToggled = false;
        
        await tester.pumpWidget(createPostListItem(
          onFavoriteToggle: () => favoriteToggled = true,
        ));

        await tester.tap(find.byIcon(Icons.favorite_border));
        expect(favoriteToggled, isTrue);
      });
    });

    group('Optimistic State', () {
      testWidgets('should display syncing indicator for optimistic posts', (tester) async {
        final optimisticPost = testPost.copyWith(isOptimistic: true);
        
        await tester.pumpWidget(createPostListItem(post: optimisticPost));

        expect(find.byIcon(Icons.sync), findsOneWidget);
        expect(find.text('Syncing...'), findsOneWidget);
      });

      testWidgets('should not display syncing indicator for normal posts', (tester) async {
        await tester.pumpWidget(createPostListItem());

        expect(find.byIcon(Icons.sync), findsNothing);
        expect(find.text('Syncing...'), findsNothing);
      });
    });

    group('Actions', () {
      testWidgets('should display action buttons when showActions is true', (tester) async {
        await tester.pumpWidget(createPostListItem(
          onComment: () {},
          onShare: () {},
          showActions: true,
        ));

        expect(find.byIcon(Icons.comment_outlined), findsOneWidget);
        expect(find.byIcon(Icons.share_outlined), findsOneWidget);
        expect(find.byIcon(Icons.more_vert), findsOneWidget);
      });

      testWidgets('should not display action buttons when showActions is false', (tester) async {
        await tester.pumpWidget(createPostListItem(
          onComment: () {},
          onShare: () {},
          showActions: false,
        ));

        expect(find.byIcon(Icons.comment_outlined), findsNothing);
        expect(find.byIcon(Icons.share_outlined), findsNothing);
        expect(find.byIcon(Icons.more_vert), findsNothing);
      });

      testWidgets('should call onComment when comment button is tapped', (tester) async {
        bool commentTapped = false;
        
        await tester.pumpWidget(createPostListItem(
          onComment: () => commentTapped = true,
        ));

        await tester.tap(find.byIcon(Icons.comment_outlined));
        expect(commentTapped, isTrue);
      });

      testWidgets('should call onShare when share button is tapped', (tester) async {
        bool shareTapped = false;
        
        await tester.pumpWidget(createPostListItem(
          onShare: () => shareTapped = true,
        ));

        await tester.tap(find.byIcon(Icons.share_outlined));
        expect(shareTapped, isTrue);
      });
    });

    group('Compact Mode', () {
      testWidgets('should display compact layout when isCompact is true', (tester) async {
        await tester.pumpWidget(createPostListItem(isCompact: true));

        // Should still display content but in compact form
        expect(find.text('Test Post Title'), findsOneWidget);
        expect(find.text('User 123'), findsOneWidget);
        
        // Actions should not be displayed in compact mode
        expect(find.byIcon(Icons.comment_outlined), findsNothing);
        expect(find.byIcon(Icons.share_outlined), findsNothing);
      });

      testWidgets('should display favorite button in header for compact mode', (tester) async {
        await tester.pumpWidget(createPostListItem(isCompact: true));

        // Favorite button should be in header for compact mode
        expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      });
    });

    group('Interaction', () {
      testWidgets('should call onTap when card is tapped', (tester) async {
        bool cardTapped = false;
        
        await tester.pumpWidget(createPostListItem(
          onTap: () => cardTapped = true,
        ));

        await tester.tap(find.byType(Card));
        expect(cardTapped, isTrue);
      });

      testWidgets('should show popup menu when more button is tapped', (tester) async {
        await tester.pumpWidget(createPostListItem());

        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pumpAndSettle();

        expect(find.text('Copy link'), findsOneWidget);
        expect(find.text('Report'), findsOneWidget);
      });
    });

    group('Date Formatting', () {
      testWidgets('should display "Just now" for very recent posts', (tester) async {
        final recentPost = testPost.copyWith(
          createdAt: DateTime.now().subtract(const Duration(seconds: 30)),
        );
        
        await tester.pumpWidget(createPostListItem(post: recentPost));

        expect(find.text('Just now'), findsOneWidget);
      });

      testWidgets('should display minutes ago for posts within an hour', (tester) async {
        final recentPost = testPost.copyWith(
          createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        );
        
        await tester.pumpWidget(createPostListItem(post: recentPost));

        expect(find.text('30m ago'), findsOneWidget);
      });

      testWidgets('should display hours ago for posts within a day', (tester) async {
        await tester.pumpWidget(createPostListItem());

        expect(find.text('2h ago'), findsOneWidget);
      });

      testWidgets('should display days ago for posts within a week', (tester) async {
        final oldPost = testPost.copyWith(
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
        );
        
        await tester.pumpWidget(createPostListItem(post: oldPost));

        expect(find.text('3d ago'), findsOneWidget);
      });

      testWidgets('should display full date for posts older than a week', (tester) async {
        final oldPost = testPost.copyWith(
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
        );
        
        await tester.pumpWidget(createPostListItem(post: oldPost));

        // Should display date in DD/MM/YYYY format
        final expectedDate = oldPost.createdAt!;
        final expectedText = '${expectedDate.day}/${expectedDate.month}/${expectedDate.year}';
        expect(find.text(expectedText), findsOneWidget);
      });
    });

    group('Search Highlighting', () {
      testWidgets('should use SearchHighlightText when searchQuery is provided', (tester) async {
        await tester.pumpWidget(createPostListItem(
          searchQuery: 'Test',
        ));

        // Should find RichText widgets for highlighted content
        expect(find.byType(RichText), findsAtLeastNWidgets(1));
      });

      testWidgets('should use regular Text when no searchQuery provided', (tester) async {
        await tester.pumpWidget(createPostListItem());

        // Should find regular Text widgets
        expect(find.text('Test Post Title'), findsOneWidget);
      });

      testWidgets('should highlight matching text in title and body', (tester) async {
        await tester.pumpWidget(createPostListItem(
          searchQuery: 'test',
        ));

        // Should find RichText widgets for both title and body
        expect(find.byType(RichText), findsAtLeastNWidgets(2));
      });

      testWidgets('should handle empty search query gracefully', (tester) async {
        await tester.pumpWidget(createPostListItem(
          searchQuery: '',
        ));

        // Should use regular Text widgets when search query is empty
        expect(find.text('Test Post Title'), findsOneWidget);
      });
    });
  });

  group('CompactPostListItem', () {
    late Post testPost;

    setUp(() {
      testPost = Post(
        id: 1,
        title: 'Test Post',
        body: 'Test body',
        userId: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    testWidgets('should create a compact post list item', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CompactPostListItem(
              post: testPost,
              onTap: () {},
              onFavoriteToggle: () {},
            ),
          ),
        ),
      );

      expect(find.text('Test Post'), findsOneWidget);
      expect(find.text('User 1'), findsOneWidget);
      expect(find.byType(PostListItem), findsOneWidget);
    });
  });

  group('PostListItemShimmer', () {
    testWidgets('should display shimmer loading effect', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PostListItemShimmer(),
          ),
        ),
      );

      expect(find.byType(PostListItemShimmer), findsOneWidget);
      expect(find.byType(Container), findsWidgets); // Shimmer containers
    });

    testWidgets('should display compact shimmer when isCompact is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PostListItemShimmer(isCompact: true),
          ),
        ),
      );

      expect(find.byType(PostListItemShimmer), findsOneWidget);
    });
  });
}