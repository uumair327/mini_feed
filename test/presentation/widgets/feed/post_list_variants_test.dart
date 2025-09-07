import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mini_feed/domain/entities/post.dart';
import 'package:mini_feed/presentation/widgets/feed/post_list_variants.dart';

void main() {
  late Post testPost;

  setUp(() {
    testPost = Post(
      id: 1,
      title: 'Test Post Title',
      body: 'This is a test post body with some content to display.',
      userId: 123,
      isFavorite: false,
      isOptimistic: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      updatedAt: DateTime.now(),
    );
  });

  group('PostGridItem', () {
    Widget createPostGridItem({
      Post? post,
      VoidCallback? onTap,
      VoidCallback? onFavoriteToggle,
      VoidCallback? onShare,
      VoidCallback? onComment,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 200,
            height: 300,
            child: PostGridItem(
              post: post ?? testPost,
              onTap: onTap ?? () {},
              onFavoriteToggle: onFavoriteToggle ?? () {},
              onShare: onShare,
              onComment: onComment,
            ),
          ),
        ),
      );
    }

    testWidgets('should display post content in grid format', (tester) async {
      await tester.pumpWidget(createPostGridItem());

      expect(find.text('Test Post Title'), findsOneWidget);
      expect(find.text('This is a test post body with some content to display.'), findsOneWidget);
      expect(find.text('User 123'), findsOneWidget);
    });

    testWidgets('should display avatar and favorite button in header', (tester) async {
      await tester.pumpWidget(createPostGridItem());

      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.text('T'), findsOneWidget); // First letter of title
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    });

    testWidgets('should call callbacks when buttons are tapped', (tester) async {
      bool favoriteToggled = false;
      bool commentTapped = false;
      bool shareTapped = false;

      await tester.pumpWidget(createPostGridItem(
        onFavoriteToggle: () => favoriteToggled = true,
        onComment: () => commentTapped = true,
        onShare: () => shareTapped = true,
      ));

      await tester.tap(find.byIcon(Icons.favorite_border));
      expect(favoriteToggled, isTrue);

      await tester.tap(find.byIcon(Icons.comment_outlined));
      expect(commentTapped, isTrue);

      await tester.tap(find.byIcon(Icons.share_outlined));
      expect(shareTapped, isTrue);
    });
  });

  group('MinimalPostListItem', () {
    Widget createMinimalPostListItem({
      Post? post,
      VoidCallback? onTap,
      VoidCallback? onFavoriteToggle,
      bool showFavorite = true,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: MinimalPostListItem(
            post: post ?? testPost,
            onTap: onTap ?? () {},
            onFavoriteToggle: onFavoriteToggle,
            showFavorite: showFavorite,
          ),
        ),
      );
    }

    testWidgets('should display post content in minimal format', (tester) async {
      await tester.pumpWidget(createMinimalPostListItem());

      expect(find.text('Test Post Title'), findsOneWidget);
      expect(find.text('User 123'), findsOneWidget);
      expect(find.byType(ListTile), findsOneWidget);
    });

    testWidgets('should show favorite button when showFavorite is true', (tester) async {
      await tester.pumpWidget(createMinimalPostListItem(
        onFavoriteToggle: () {},
        showFavorite: true,
      ));

      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    });

    testWidgets('should hide favorite button when showFavorite is false', (tester) async {
      await tester.pumpWidget(createMinimalPostListItem(
        showFavorite: false,
      ));

      expect(find.byIcon(Icons.favorite_border), findsNothing);
    });

    testWidgets('should display optimistic indicator', (tester) async {
      final optimisticPost = testPost.copyWith(isOptimistic: true);
      
      await tester.pumpWidget(createMinimalPostListItem(post: optimisticPost));

      expect(find.byIcon(Icons.sync), findsOneWidget);
    });

    testWidgets('should call onTap when tapped', (tester) async {
      bool tapped = false;
      
      await tester.pumpWidget(createMinimalPostListItem(
        onTap: () => tapped = true,
      ));

      await tester.tap(find.byType(ListTile));
      expect(tapped, isTrue);
    });
  });

  group('FeaturedPostListItem', () {
    Widget createFeaturedPostListItem({
      Post? post,
      VoidCallback? onTap,
      VoidCallback? onFavoriteToggle,
      VoidCallback? onShare,
      VoidCallback? onComment,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: FeaturedPostListItem(
            post: post ?? testPost,
            onTap: onTap ?? () {},
            onFavoriteToggle: onFavoriteToggle ?? () {},
            onShare: onShare,
            onComment: onComment,
          ),
        ),
      );
    }

    testWidgets('should display featured badge', (tester) async {
      await tester.pumpWidget(createFeaturedPostListItem());

      expect(find.text('FEATURED'), findsOneWidget);
    });

    testWidgets('should display post content in featured format', (tester) async {
      await tester.pumpWidget(createFeaturedPostListItem());

      expect(find.text('Test Post Title'), findsOneWidget);
      expect(find.text('This is a test post body with some content to display.'), findsOneWidget);
      expect(find.text('User 123'), findsOneWidget);
    });

    testWidgets('should display larger avatar', (tester) async {
      await tester.pumpWidget(createFeaturedPostListItem());

      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.text('T'), findsOneWidget); // First letter of title
    });

    testWidgets('should display action buttons when provided', (tester) async {
      await tester.pumpWidget(createFeaturedPostListItem(
        onComment: () {},
        onShare: () {},
      ));

      expect(find.text('Comments'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
    });

    testWidgets('should call callbacks when buttons are tapped', (tester) async {
      bool favoriteToggled = false;
      bool commentTapped = false;
      bool shareTapped = false;

      await tester.pumpWidget(createFeaturedPostListItem(
        onFavoriteToggle: () => favoriteToggled = true,
        onComment: () => commentTapped = true,
        onShare: () => shareTapped = true,
      ));

      await tester.tap(find.byIcon(Icons.favorite_border));
      expect(favoriteToggled, isTrue);

      await tester.tap(find.text('Comments'));
      expect(commentTapped, isTrue);

      await tester.tap(find.text('Share'));
      expect(shareTapped, isTrue);
    });

    testWidgets('should display optimistic indicator', (tester) async {
      final optimisticPost = testPost.copyWith(isOptimistic: true);
      
      await tester.pumpWidget(createFeaturedPostListItem(post: optimisticPost));

      expect(find.byIcon(Icons.sync), findsOneWidget);
      expect(find.text('Syncing...'), findsOneWidget);
    });

    testWidgets('should call onTap when card is tapped', (tester) async {
      bool tapped = false;
      
      await tester.pumpWidget(createFeaturedPostListItem(
        onTap: () => tapped = true,
      ));

      await tester.tap(find.byType(Card));
      expect(tapped, isTrue);
    });
  });

  group('Date Formatting', () {
    testWidgets('PostGridItem should format dates correctly', (tester) async {
      final recentPost = testPost.copyWith(
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 300,
              child: PostGridItem(
                post: recentPost,
                onTap: () {},
                onFavoriteToggle: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('30m'), findsOneWidget);
    });

    testWidgets('MinimalPostListItem should format dates correctly', (tester) async {
      final recentPost = testPost.copyWith(
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MinimalPostListItem(
              post: recentPost,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('1h'), findsOneWidget);
    });

    testWidgets('FeaturedPostListItem should format dates correctly', (tester) async {
      final recentPost = testPost.copyWith(
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FeaturedPostListItem(
              post: recentPost,
              onTap: () {},
              onFavoriteToggle: () {},
            ),
          ),
        ),
      );

      expect(find.text('5 minutes ago'), findsOneWidget);
    });
  });
}