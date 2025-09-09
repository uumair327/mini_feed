import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';

import 'package:mini_feed/domain/entities/post.dart';
import 'package:mini_feed/domain/usecases/posts/create_post_usecase.dart';
import 'package:mini_feed/domain/usecases/posts/get_posts_usecase.dart';
import 'package:mini_feed/domain/usecases/posts/search_posts_usecase.dart';
import 'package:mini_feed/presentation/blocs/post_creation/post_creation_bloc.dart';
import 'package:mini_feed/presentation/blocs/post_creation/post_creation_event.dart';
import 'package:mini_feed/presentation/blocs/post_creation/post_creation_state.dart';
import 'package:mini_feed/presentation/blocs/feed/feed_bloc.dart';
import 'package:mini_feed/presentation/blocs/feed/feed_event.dart';
import 'package:mini_feed/presentation/blocs/feed/feed_state.dart';
import 'package:mini_feed/core/errors/failures.dart';
import 'package:mini_feed/core/utils/result.dart';

class MockCreatePostUseCase extends Mock implements CreatePostUseCase {}
class MockGetPostsUseCase extends Mock implements GetPostsUseCase {}
class MockSearchPostsUseCase extends Mock implements SearchPostsUseCase {}

class FakeCreatePostParams extends Fake implements CreatePostParams {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeCreatePostParams());
  });
  group('Optimistic Post Creation End-to-End Tests', () {
    late PostCreationBloc postCreationBloc;
    late FeedBloc feedBloc;
    late MockCreatePostUseCase mockCreatePostUseCase;
    late MockGetPostsUseCase mockGetPostsUseCase;
    late MockSearchPostsUseCase mockSearchPostsUseCase;

    setUp(() {
      mockCreatePostUseCase = MockCreatePostUseCase();
      mockGetPostsUseCase = MockGetPostsUseCase();
      mockSearchPostsUseCase = MockSearchPostsUseCase();
      
      postCreationBloc = PostCreationBloc(
        createPostUseCase: mockCreatePostUseCase,
      );
      
      // Mock FeedBloc with required dependencies
      feedBloc = FeedBloc(
        getPostsUseCase: mockGetPostsUseCase,
        searchPostsUseCase: mockSearchPostsUseCase,
      );
    });

    tearDown(() {
      postCreationBloc.close();
      feedBloc.close();
    });

    test('should handle complete optimistic post creation flow', () async {
      // Arrange
      const title = 'My Optimistic Post';
      const body = 'This post should appear immediately and then be confirmed.';
      const userId = 1;
      
      final expectedPost = Post(
        id: 123,
        userId: userId,
        title: title,
        body: body,
        isFavorite: false,
        isOptimistic: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(() => mockCreatePostUseCase(any()))
          .thenAnswer((_) async => success(expectedPost));

      // Set up feed with some existing posts
      final existingPosts = [
        Post(id: 1, userId: 1, title: 'Post 1', body: 'Body 1'),
        Post(id: 2, userId: 1, title: 'Post 2', body: 'Body 2'),
      ];
      
      feedBloc.emit(FeedLoaded(
        posts: existingPosts,
        hasReachedMax: false,
        currentPage: 1,
      ));

      // Act & Assert - Complete optimistic flow
      final postCreationStates = <PostCreationState>[];
      final feedStates = <FeedState>[];
      
      final postCreationSubscription = postCreationBloc.stream.listen(postCreationStates.add);
      final feedSubscription = feedBloc.stream.listen(feedStates.add);

      // Step 1: Validate input
      postCreationBloc.add(const PostInputValidated(
        title: title,
        body: body,
      ));

      await Future.delayed(const Duration(milliseconds: 10));

      // Step 2: Create post (this should trigger optimistic creation)
      postCreationBloc.add(const PostCreationRequested(
        title: title,
        body: body,
        userId: userId,
      ));

      // Wait for async operations to complete
      await Future.delayed(const Duration(milliseconds: 100));

      await postCreationSubscription.cancel();
      await feedSubscription.cancel();

      // Verify post creation flow
      expect(postCreationStates.length, greaterThanOrEqualTo(3));
      
      // Should have validation state
      expect(
        postCreationStates.any((state) => 
          state is PostCreationValidating && 
          state.isValid && 
          state.titleError == null && 
          state.bodyError == null
        ),
        isTrue,
      );
      
      // Should have loading state with optimistic post
      expect(
        postCreationStates.any((state) => 
          state is PostCreationLoading && 
          state.optimisticPost != null &&
          state.optimisticPost!.title == title &&
          state.optimisticPost!.body == body &&
          state.optimisticPost!.isOptimistic == true
        ),
        isTrue,
      );
      
      // Should have success state
      expect(
        postCreationStates.any((state) => 
          state is PostCreationSuccess && 
          state.createdPost.title == title &&
          state.createdPost.body == body &&
          state.createdPost.isOptimistic == false
        ),
        isTrue,
      );

      // Verify use case interaction
      verify(() => mockCreatePostUseCase(any())).called(1);
    });

    test('should handle optimistic post creation failure with rollback', () async {
      // Arrange
      const title = 'Failed Post';
      const body = 'This post will fail to create and should be rolled back.';
      const userId = 1;

      when(() => mockCreatePostUseCase.call(any()))
          .thenAnswer((_) async => Left(NetworkFailure('Network connection failed')));

      // Set up feed with existing posts
      final existingPosts = [
        Post(id: 1, userId: 1, title: 'Post 1', body: 'Body 1'),
        Post(id: 2, userId: 1, title: 'Post 2', body: 'Body 2'),
      ];
      
      feedBloc.emit(FeedLoaded(
        posts: existingPosts,
        hasReachedMax: false,
        currentPage: 1,
      ));

      // Act
      final postCreationStates = <PostCreationState>[];
      final postCreationSubscription = postCreationBloc.stream.listen(postCreationStates.add);

      postCreationBloc.add(const PostCreationRequested(
        title: title,
        body: body,
        userId: userId,
      ));

      // Wait for async operations to complete
      await Future.delayed(const Duration(milliseconds: 100));
      await postCreationSubscription.cancel();

      // Assert
      expect(postCreationStates.length, greaterThanOrEqualTo(2));
      
      // Should have loading state with optimistic post
      expect(
        postCreationStates.any((state) => 
          state is PostCreationLoading && 
          state.optimisticPost != null
        ),
        isTrue,
      );
      
      // Should have failure state
      expect(
        postCreationStates.any((state) => 
          state is PostCreationFailure && 
          state.canRetry == true
        ),
        isTrue,
      );

      // Verify use case was called
      verify(() => mockCreatePostUseCase.call(any())).called(1);
    });

    test('should handle input validation before optimistic creation', () async {
      // Arrange - Invalid input
      const invalidTitle = 'ab'; // Too short
      const invalidBody = 'short'; // Too short

      // Act
      final postCreationStates = <PostCreationState>[];
      final postCreationSubscription = postCreationBloc.stream.listen(postCreationStates.add);

      postCreationBloc.add(const PostInputValidated(
        title: invalidTitle,
        body: invalidBody,
      ));

      await Future.delayed(const Duration(milliseconds: 10));
      await postCreationSubscription.cancel();

      // Assert
      expect(postCreationStates.length, greaterThanOrEqualTo(1));
      
      // Should have validation state with errors
      expect(
        postCreationStates.any((state) => 
          state is PostCreationValidating && 
          !state.isValid &&
          state.titleError != null &&
          state.bodyError != null
        ),
        isTrue,
      );

      // Should not attempt to create post with invalid input
      verifyNever(() => mockCreatePostUseCase.call(any()));
    });

    test('should handle retry after failed optimistic creation', () async {
      // Arrange
      const title = 'Retry Post';
      const body = 'This post will fail first, then succeed on retry.';
      const userId = 1;
      
      final successPost = Post(
        id: 456,
        userId: userId,
        title: title,
        body: body,
        isFavorite: false,
        isOptimistic: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // First call fails, second succeeds
      when(() => mockCreatePostUseCase.call(any()))
          .thenAnswer((_) async => Left(NetworkFailure('Network connection failed')));
      
      // Set up second call to succeed
      when(() => mockCreatePostUseCase.call(any()))
          .thenAnswer((_) async => Right(successPost));

      // Act - First attempt
      final postCreationStates = <PostCreationState>[];
      final postCreationSubscription = postCreationBloc.stream.listen(postCreationStates.add);

      postCreationBloc.add(const PostCreationRequested(
        title: title,
        body: body,
        userId: userId,
      ));

      // Wait for failure
      await Future.delayed(const Duration(milliseconds: 100));

      // Clear states and retry
      postCreationStates.clear();
      
      postCreationBloc.add(const PostCreationRequested(
        title: title,
        body: body,
        userId: userId,
      ));

      // Wait for success
      await Future.delayed(const Duration(milliseconds: 100));
      await postCreationSubscription.cancel();

      // Assert - Should succeed on retry
      expect(
        postCreationStates.any((state) => 
          state is PostCreationSuccess &&
          state.createdPost.title == title
        ),
        isTrue,
      );

      // Verify use case was called twice
      verify(() => mockCreatePostUseCase.call(any())).called(2);
    });

    test('should maintain state consistency during rapid operations', () async {
      // Arrange
      const title = 'Rapid Post';
      const body = 'This tests rapid state changes during optimistic creation.';
      const userId = 1;
      
      final expectedPost = Post(
        id: 789,
        userId: userId,
        title: title,
        body: body,
        isFavorite: false,
        isOptimistic: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(() => mockCreatePostUseCase.call(any()))
          .thenAnswer((_) async {
        // Simulate network delay
        await Future.delayed(const Duration(milliseconds: 50));
        return Right(expectedPost);
      });

      // Act - Rapid operations
      final postCreationStates = <PostCreationState>[];
      final postCreationSubscription = postCreationBloc.stream.listen(postCreationStates.add);

      // Rapid validation changes
      postCreationBloc.add(const PostInputValidated(title: 'T', body: 'T'));
      postCreationBloc.add(const PostInputValidated(title: 'Te', body: 'Te'));
      postCreationBloc.add(const PostInputValidated(title: title, body: body));
      
      // Submit
      postCreationBloc.add(const PostCreationRequested(
        title: title,
        body: body,
        userId: userId,
      ));

      // Wait for completion
      await Future.delayed(const Duration(milliseconds: 150));
      await postCreationSubscription.cancel();

      // Assert - Should end in success state
      expect(
        postCreationBloc.state,
        isA<PostCreationSuccess>(),
      );

      // Should have processed all states correctly
      expect(postCreationStates.length, greaterThan(3));
      
      // Should only call use case once despite rapid state changes
      verify(() => mockCreatePostUseCase.call(any())).called(1);
    });
  });
}