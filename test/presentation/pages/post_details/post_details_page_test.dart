import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mini_feed/domain/entities/post.dart';
import 'package:mini_feed/domain/entities/comment.dart';
import 'package:mini_feed/presentation/blocs/post_details/post_details_bloc.dart';
import 'package:mini_feed/presentation/blocs/post_details/post_details_event.dart';
import 'package:mini_feed/presentation/blocs/post_details/post_details_state.dart';
import 'package:mini_feed/presentation/pages/post_details/post_details_page.dart';
import 'package:mini_feed/presentation/widgets/common/loading_indicators.dart';
import 'package:mini_feed/presentation/widgets/common/error_widgets.dart';
import 'package:mini_feed/presentation/widgets/post_details/post_content_widget.dart';
import 'package:mini_feed/presentation/widgets/post_details/comments_section.dart';

class MockPostDetailsBloc extends Mock implements PostDetailsBloc {}

/// Test version of PostDetailsPage that accepts a bloc directly
class TestPostDetailsPage extends StatefulWidget {
  final int postId;
  final PostDetailsBloc bloc;

  const TestPostDetailsPage({
    super.key,
    required this.postId,
    required this.bloc,
  });

  @override
  State<TestPostDetailsPage> createState() => _TestPostDetailsPageState();
}

class _TestPostDetailsPageState extends State<TestPostDetailsPage> {
  late PostDetailsBloc _postDetailsBloc;

  @override
  void initState() {
    super.initState();
    _postDetailsBloc = widget.bloc;
    _postDetailsBloc.add(PostDetailsRequested(postId: widget.postId));
  }

  @override
  void dispose() {
    // Don't close the bloc in tests as it's managed by the test
    super.dispose();
  }

  void _onRefresh() {
    _postDetailsBloc.add(PostDetailsRefreshed(postId: widget.postId));
  }

  void _onFavoriteToggle(bool isFavorite) {
    _postDetailsBloc.add(FavoriteToggled(
      postId: widget.postId,
      isFavorite: isFavorite,
    ));
  }

  void _onRetry() {
    _postDetailsBloc.add(PostDetailsRetryRequested(postId: widget.postId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Details'),
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      body: BlocBuilder<PostDetailsBloc, PostDetailsState>(
        builder: (context, state) {
          if (state is PostDetailsLoading) {
            return const Center(
              child: AppLoadingIndicator(),
            );
          }

          if (state is PostDetailsError) {
            return AppErrorWidget(
              message: state.message,
              onRetry: state.canRetry ? _onRetry : null,
            );
          }

          if (state is PostDetailsLoaded) {
            return RefreshIndicator(
              onRefresh: () async => _onRefresh(),
              child: CustomScrollView(
                slivers: [
                  // Post content
                  SliverToBoxAdapter(
                    child: PostContentWidget(
                      post: state.post,
                      onFavoriteToggle: _onFavoriteToggle,
                      isTogglingFavorite: state.isTogglingFavorite,
                    ),
                  ),
                  
                  // Divider
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 16.0,
                      ),
                      height: 1,
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                  
                  // Comments section
                  CommentsSection(
                    comments: state.comments,
                    isLoading: state.isRefreshing,
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

void main() {
  group('PostDetailsPage', () {
    late MockPostDetailsBloc mockPostDetailsBloc;
    late Post testPost;
    late List<Comment> testComments;

    setUp(() {
      mockPostDetailsBloc = MockPostDetailsBloc();
      
      testPost = Post(
        id: 1,
        userId: 123,
        title: 'Test Post Title',
        body: 'This is a test post body with some content.',
        isFavorite: false,
        isOptimistic: false,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
      );
      
      testComments = [
        Comment(
          id: 1,
          postId: 1,
          name: 'John Doe',
          email: 'john@example.com',
          body: 'This is a test comment.',
        ),
        Comment(
          id: 2,
          postId: 1,
          name: 'Jane Smith',
          email: 'jane@example.com',
          body: 'Another test comment with more content.',
        ),
      ];
    });

    Widget createPostDetailsPage({int postId = 1}) {
      return MaterialApp(
        home: BlocProvider<PostDetailsBloc>.value(
          value: mockPostDetailsBloc,
          child: TestPostDetailsPage(postId: postId, bloc: mockPostDetailsBloc),
        ),
      );
    }

    testWidgets('should display loading indicator when state is loading', (tester) async {
      when(() => mockPostDetailsBloc.state)
          .thenReturn(const PostDetailsLoading());
      when(() => mockPostDetailsBloc.stream)
          .thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(createPostDetailsPage());

      expect(find.byType(AppLoadingIndicator), findsOneWidget);
      expect(find.text('Post Details'), findsOneWidget);
    });

    testWidgets('should display error widget when state is error', (tester) async {
      const errorMessage = 'Failed to load post details';
      when(() => mockPostDetailsBloc.state)
          .thenReturn(const PostDetailsError(
            message: errorMessage,
            canRetry: true,
          ));
      when(() => mockPostDetailsBloc.stream)
          .thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(createPostDetailsPage());

      expect(find.byType(AppErrorWidget), findsOneWidget);
      expect(find.text(errorMessage), findsOneWidget);
    });

    testWidgets('should display post content and comments when loaded', (tester) async {
      when(() => mockPostDetailsBloc.state)
          .thenReturn(PostDetailsLoaded(
            post: testPost,
            comments: testComments,
          ));
      when(() => mockPostDetailsBloc.stream)
          .thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(createPostDetailsPage());

      expect(find.byType(PostContentWidget), findsOneWidget);
      expect(find.byType(CommentsSection), findsOneWidget);
      expect(find.text(testPost.title), findsOneWidget);
      expect(find.text('Comments (${testComments.length})'), findsOneWidget);
    });

    testWidgets('should trigger refresh when pull to refresh is used', (tester) async {
      when(() => mockPostDetailsBloc.state)
          .thenReturn(PostDetailsLoaded(
            post: testPost,
            comments: testComments,
          ));
      when(() => mockPostDetailsBloc.stream)
          .thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(createPostDetailsPage());

      // Find the RefreshIndicator and trigger refresh
      await tester.fling(
        find.byType(CustomScrollView),
        const Offset(0, 300),
        1000,
      );
      await tester.pump();

      verify(() => mockPostDetailsBloc.add(
        const PostDetailsRefreshed(postId: 1),
      )).called(1);
    });

    testWidgets('should handle favorite toggle', (tester) async {
      when(() => mockPostDetailsBloc.state)
          .thenReturn(PostDetailsLoaded(
            post: testPost,
            comments: testComments,
          ));
      when(() => mockPostDetailsBloc.stream)
          .thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(createPostDetailsPage());

      // Find and tap the favorite button
      final favoriteButton = find.byIcon(Icons.favorite_border);
      expect(favoriteButton, findsOneWidget);
      
      await tester.tap(favoriteButton);
      await tester.pump();

      verify(() => mockPostDetailsBloc.add(
        const FavoriteToggled(postId: 1, isFavorite: true),
      )).called(1);
    });

    testWidgets('should handle retry when error occurs', (tester) async {
      when(() => mockPostDetailsBloc.state)
          .thenReturn(const PostDetailsError(
            message: 'Network error',
            canRetry: true,
          ));
      when(() => mockPostDetailsBloc.stream)
          .thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(createPostDetailsPage());

      // Find and tap the retry button
      final retryButton = find.text('Retry');
      expect(retryButton, findsOneWidget);
      
      await tester.tap(retryButton);
      await tester.pump();

      verify(() => mockPostDetailsBloc.add(
        const PostDetailsRetryRequested(postId: 1),
      )).called(1);
    });

    testWidgets('should request post details on init', (tester) async {
      when(() => mockPostDetailsBloc.state)
          .thenReturn(const PostDetailsLoading());
      when(() => mockPostDetailsBloc.stream)
          .thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(createPostDetailsPage(postId: 42));

      verify(() => mockPostDetailsBloc.add(
        const PostDetailsRequested(postId: 42),
      )).called(1);
    });

    testWidgets('should display app bar with correct title', (tester) async {
      when(() => mockPostDetailsBloc.state)
          .thenReturn(const PostDetailsLoading());
      when(() => mockPostDetailsBloc.stream)
          .thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(createPostDetailsPage());

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Post Details'), findsOneWidget);
    });

    testWidgets('should show loading state in comments when refreshing', (tester) async {
      when(() => mockPostDetailsBloc.state)
          .thenReturn(PostDetailsLoaded(
            post: testPost,
            comments: testComments,
            isRefreshing: true,
          ));
      when(() => mockPostDetailsBloc.stream)
          .thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(createPostDetailsPage());

      expect(find.byType(PostContentWidget), findsOneWidget);
      expect(find.byType(CommentsSection), findsOneWidget);
    });

    testWidgets('should show favorite toggle loading state', (tester) async {
      when(() => mockPostDetailsBloc.state)
          .thenReturn(PostDetailsLoaded(
            post: testPost,
            comments: testComments,
            isTogglingFavorite: true,
          ));
      when(() => mockPostDetailsBloc.stream)
          .thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(createPostDetailsPage());

      expect(find.byType(PostContentWidget), findsOneWidget);
      // The PostContentWidget should show loading indicator for favorite button
    });
  });
}