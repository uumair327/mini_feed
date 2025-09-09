import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mini_feed/domain/entities/post.dart';
import 'package:mini_feed/domain/usecases/posts/get_posts_usecase.dart';
import 'package:mini_feed/domain/usecases/posts/search_posts_usecase.dart';
import 'package:mini_feed/presentation/blocs/feed/feed_bloc.dart';
import 'package:mini_feed/presentation/blocs/feed/feed_event.dart';
import 'package:mini_feed/presentation/blocs/feed/feed_state.dart';
import 'package:mini_feed/core/utils/result.dart';

class MockGetPostsUseCase extends Mock implements GetPostsUseCase {}
class MockSearchPostsUseCase extends Mock implements SearchPostsUseCase {}

void main() {
  group('FeedBloc Optimistic Updates', () {
    late FeedBloc feedBloc;
    late MockGetPostsUseCase mockGetPostsUseCase;
    late MockSearchPostsUseCase mockSearchPostsUseCase;

    setUp(() {
      mockGetPostsUseCase = MockGetPostsUseCase();
      mockSearchPostsUseCase = MockSearchPostsUseCase();
      
      feedBloc = FeedBloc(
        getPostsUseCase: mockGetPostsUseCase,
        searchPostsUseCase: mockSearchPostsUseCase,
      );
    });

    tearDown(() {
      feedBloc.close();
    });

    group('OptimisticPostAdded', () {
      test('should add optimistic post to loaded feed', () async {
        // Arrange
        final existingPosts = [
          Post(id: 1, userId: 1, title: 'Post 1', body: 'Body 1'),
          Post(id: 2, userId: 1, title: 'Post 2', body: 'Body 2'),
        ];
        
        final optimisticPost = Post(
          id: -1,
          userId: 1,
          title: 'New Post',
          body: 'New Body',
          isOptimistic: true,
        );

        // Set initial state
        feedBloc.emit(FeedLoaded(
          posts: existingPosts,
          hasReachedMax: false,
          currentPage: 1,
        ));

        // Act
        feedBloc.add(OptimisticPostAdded(optimisticPost: optimisticPost));

        // Assert
        await expectLater(
          feedBloc.stream,
          emits(
            isA<FeedLoaded>()
                .having((state) => state.posts.length, 'posts length', 3)
                .having((state) => state.posts.first, 'first post', optimisticPost),
          ),
        );
      });

      test('should create loaded state from empty feed', () async {
        // Arrange
        final optimisticPost = Post(
          id: -1,
          userId: 1,
          title: 'New Post',
          body: 'New Body',
          isOptimistic: true,
        );

        // Set initial state
        feedBloc.emit(const FeedEmpty());

        // Act
        feedBloc.add(OptimisticPostAdded(optimisticPost: optimisticPost));

        // Assert
        await expectLater(
          feedBloc.stream,
          emits(
            isA<FeedLoaded>()
                .having((state) => state.posts.length, 'posts length', 1)
                .having((state) => state.posts.first, 'first post', optimisticPost),
          ),
        );
      });

      test('should not add optimistic post when feed is loading', () async {
        // Arrange
        final optimisticPost = Post(
          id: -1,
          userId: 1,
          title: 'New Post',
          body: 'New Body',
          isOptimistic: true,
        );

        // Set initial state
        feedBloc.emit(const FeedLoading());

        // Act
        feedBloc.add(OptimisticPostAdded(optimisticPost: optimisticPost));

        // Assert - state should remain loading
        expect(feedBloc.state, isA<FeedLoading>());
      });
    });

    group('OptimisticPostReplaced', () {
      test('should replace optimistic post with real post', () async {
        // Arrange
        final optimisticPost = Post(
          id: -1,
          userId: 1,
          title: 'New Post',
          body: 'New Body',
          isOptimistic: true,
        );
        
        final realPost = Post(
          id: 100,
          userId: 1,
          title: 'New Post',
          body: 'New Body',
          isOptimistic: false,
        );

        final existingPosts = [
          optimisticPost,
          Post(id: 1, userId: 1, title: 'Post 1', body: 'Body 1'),
        ];

        // Set initial state
        feedBloc.emit(FeedLoaded(
          posts: existingPosts,
          hasReachedMax: false,
          currentPage: 1,
        ));

        // Act
        feedBloc.add(OptimisticPostReplaced(
          optimisticPost: optimisticPost,
          realPost: realPost,
        ));

        // Assert
        await expectLater(
          feedBloc.stream,
          emits(
            isA<FeedLoaded>()
                .having((state) => state.posts.length, 'posts length', 2)
                .having((state) => state.posts.first, 'first post', realPost)
                .having((state) => state.posts.first.isOptimistic, 'is not optimistic', false),
          ),
        );
      });

      test('should not replace if optimistic post not found', () async {
        // Arrange
        final optimisticPost = Post(
          id: -1,
          userId: 1,
          title: 'New Post',
          body: 'New Body',
          isOptimistic: true,
        );
        
        final realPost = Post(
          id: 100,
          userId: 1,
          title: 'New Post',
          body: 'New Body',
          isOptimistic: false,
        );

        final existingPosts = [
          Post(id: 1, userId: 1, title: 'Post 1', body: 'Body 1'),
          Post(id: 2, userId: 1, title: 'Post 2', body: 'Body 2'),
        ];

        // Set initial state
        feedBloc.emit(FeedLoaded(
          posts: existingPosts,
          hasReachedMax: false,
          currentPage: 1,
        ));

        // Act
        feedBloc.add(OptimisticPostReplaced(
          optimisticPost: optimisticPost,
          realPost: realPost,
        ));

        // Assert - posts should remain unchanged
        await Future.delayed(const Duration(milliseconds: 100));
        
        final currentState = feedBloc.state;
        expect(currentState, isA<FeedLoaded>());
        final loadedState = currentState as FeedLoaded;
        expect(loadedState.posts.length, equals(2));
        expect(loadedState.posts, equals(existingPosts));
      });
    });

    group('OptimisticPostRemoved', () {
      test('should remove optimistic post from feed', () async {
        // Arrange
        final optimisticPost = Post(
          id: -1,
          userId: 1,
          title: 'New Post',
          body: 'New Body',
          isOptimistic: true,
        );

        final existingPosts = [
          optimisticPost,
          Post(id: 1, userId: 1, title: 'Post 1', body: 'Body 1'),
          Post(id: 2, userId: 1, title: 'Post 2', body: 'Body 2'),
        ];

        // Set initial state
        feedBloc.emit(FeedLoaded(
          posts: existingPosts,
          hasReachedMax: false,
          currentPage: 1,
        ));

        // Act
        feedBloc.add(OptimisticPostRemoved(optimisticPost: optimisticPost));

        // Assert
        await expectLater(
          feedBloc.stream,
          emits(
            isA<FeedLoaded>()
                .having((state) => state.posts.length, 'posts length', 2)
                .having((state) => state.posts.any((p) => p.isOptimistic), 'no optimistic posts', false),
          ),
        );
      });

      test('should emit empty state when removing last post', () async {
        // Arrange
        final optimisticPost = Post(
          id: -1,
          userId: 1,
          title: 'New Post',
          body: 'New Body',
          isOptimistic: true,
        );

        // Set initial state with only optimistic post
        feedBloc.emit(FeedLoaded(
          posts: [optimisticPost],
          hasReachedMax: true,
          currentPage: 1,
        ));

        // Act
        feedBloc.add(OptimisticPostRemoved(optimisticPost: optimisticPost));

        // Assert
        await expectLater(
          feedBloc.stream,
          emits(isA<FeedEmpty>()),
        );
      });

      test('should not remove if optimistic post not found', () async {
        // Arrange
        final optimisticPost = Post(
          id: -1,
          userId: 1,
          title: 'New Post',
          body: 'New Body',
          isOptimistic: true,
        );

        final existingPosts = [
          Post(id: 1, userId: 1, title: 'Post 1', body: 'Body 1'),
          Post(id: 2, userId: 1, title: 'Post 2', body: 'Body 2'),
        ];

        // Set initial state
        feedBloc.emit(FeedLoaded(
          posts: existingPosts,
          hasReachedMax: false,
          currentPage: 1,
        ));

        // Act
        feedBloc.add(OptimisticPostRemoved(optimisticPost: optimisticPost));

        // Assert - posts should remain unchanged
        await Future.delayed(const Duration(milliseconds: 100));
        
        final currentState = feedBloc.state;
        expect(currentState, isA<FeedLoaded>());
        final loadedState = currentState as FeedLoaded;
        expect(loadedState.posts.length, equals(2));
        expect(loadedState.posts, equals(existingPosts));
      });
    });
  });
}