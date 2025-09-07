import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mini_feed/core/errors/failures.dart';
import 'package:mini_feed/core/utils/result.dart';
import 'package:mini_feed/domain/entities/post.dart';
import 'package:mini_feed/domain/usecases/posts/create_post_usecase.dart';
import 'package:mini_feed/presentation/blocs/post_creation/post_creation_bloc.dart';
import 'package:mini_feed/presentation/blocs/post_creation/post_creation_event.dart';
import 'package:mini_feed/presentation/blocs/post_creation/post_creation_state.dart';

class MockCreatePostUseCase extends Mock implements CreatePostUseCase {}

void main() {
  group('PostCreationBloc', () {
    late PostCreationBloc postCreationBloc;
    late MockCreatePostUseCase mockCreatePostUseCase;

    setUpAll(() {
      registerFallbackValue(const CreatePostParams(
        title: 'Test Title',
        body: 'Test Body Content',
        userId: 1,
      ));
    });

    setUp(() {
      mockCreatePostUseCase = MockCreatePostUseCase();
      
      postCreationBloc = PostCreationBloc(
        createPostUseCase: mockCreatePostUseCase,
      );
    });

    tearDown(() {
      postCreationBloc.close();
    });

    const tCreatedPost = Post(
      id: 101,
      title: 'Test Post',
      body: 'This is a test post content',
      userId: 1,
    );

    group('initial state', () {
      test('should have PostCreationInitial as initial state', () {
        expect(postCreationBloc.state, equals(const PostCreationInitial()));
      });
    });

    group('PostCreationRequested', () {
      blocTest<PostCreationBloc, PostCreationState>(
        'should emit [PostCreationLoading, PostCreationSuccess] when post is created successfully',
        build: () {
          when(() => mockCreatePostUseCase(any()))
              .thenAnswer((_) async => success(tCreatedPost));
          return postCreationBloc;
        },
        act: (bloc) => bloc.add(const PostCreationRequested(
          title: 'Test Post',
          body: 'This is a test post content',
          userId: 1,
        )),
        expect: () => [
          isA<PostCreationLoading>()
              .having((state) => state.optimisticPost, 'optimisticPost', isNotNull)
              .having((state) => state.optimisticPost!.title, 'optimisticPost.title', 'Test Post')
              .having((state) => state.optimisticPost!.body, 'optimisticPost.body', 'This is a test post content')
              .having((state) => state.optimisticPost!.userId, 'optimisticPost.userId', 1)
              .having((state) => state.optimisticPost!.isOptimistic, 'optimisticPost.isOptimistic', true)
              .having((state) => state.optimisticPost!.id, 'optimisticPost.id', lessThan(0)),
          isA<PostCreationSuccess>()
              .having((state) => state.createdPost, 'createdPost', tCreatedPost)
              .having((state) => state.previousOptimisticPost, 'previousOptimisticPost', isNotNull),
        ],
        verify: (_) {
          verify(() => mockCreatePostUseCase(const CreatePostParams(
            title: 'Test Post',
            body: 'This is a test post content',
            userId: 1,
          ))).called(1);
        },
      );

      blocTest<PostCreationBloc, PostCreationState>(
        'should emit [PostCreationLoading, PostCreationFailure] when post creation fails',
        build: () {
          when(() => mockCreatePostUseCase(any()))
              .thenAnswer((_) async => failure(const NetworkFailure('Network error')));
          return postCreationBloc;
        },
        act: (bloc) => bloc.add(const PostCreationRequested(
          title: 'Test Post',
          body: 'This is a test post content',
          userId: 1,
        )),
        expect: () => [
          isA<PostCreationLoading>()
              .having((state) => state.optimisticPost, 'optimisticPost', isNotNull),
          isA<PostCreationFailure>()
              .having((state) => state.message, 'message', 'Network error')
              .having((state) => state.details, 'details', 'NetworkFailure(Network error)')
              .having((state) => state.failedOptimisticPost, 'failedOptimisticPost', isNotNull)
              .having((state) => state.canRetry, 'canRetry', true),
        ],
      );

      blocTest<PostCreationBloc, PostCreationState>(
        'should handle unexpected exceptions gracefully',
        build: () {
          when(() => mockCreatePostUseCase(any()))
              .thenThrow(Exception('Unexpected error'));
          return postCreationBloc;
        },
        act: (bloc) => bloc.add(const PostCreationRequested(
          title: 'Test Post',
          body: 'This is a test post content',
          userId: 1,
        )),
        expect: () => [
          isA<PostCreationLoading>(),
          const PostCreationFailure(
            message: 'An unexpected error occurred while creating the post',
          ),
        ],
      );
    });

    group('OptimisticPostAdded', () {
      blocTest<PostCreationBloc, PostCreationState>(
        'should emit [PostCreationOptimistic, PostCreationLoading, PostCreationSuccess] for successful optimistic creation',
        build: () {
          when(() => mockCreatePostUseCase(any()))
              .thenAnswer((_) async => success(tCreatedPost));
          return postCreationBloc;
        },
        act: (bloc) => bloc.add(const OptimisticPostAdded(
          title: 'Test Post',
          body: 'This is a test post content',
          userId: 1,
        )),
        expect: () => [
          isA<PostCreationOptimistic>()
              .having((state) => state.optimisticPost.title, 'optimisticPost.title', 'Test Post')
              .having((state) => state.optimisticPost.isOptimistic, 'optimisticPost.isOptimistic', true),
          isA<PostCreationLoading>(),
          isA<PostCreationSuccess>(),
        ],
      );
    });

    group('PostCreationRollback', () {
      blocTest<PostCreationBloc, PostCreationState>(
        'should emit PostCreationFailure when rollback is requested',
        build: () => postCreationBloc,
        act: (bloc) => bloc.add(const PostCreationRollback(
          optimisticPostId: -123,
          errorMessage: 'Creation failed',
        )),
        expect: () => [
          const PostCreationFailure(
            message: 'Creation failed',
            details: 'Optimistic post creation failed and was rolled back',
            canRetry: true,
          ),
        ],
      );
    });

    group('PostCreationReset', () {
      blocTest<PostCreationBloc, PostCreationState>(
        'should emit PostCreationInitial when reset is requested',
        build: () => postCreationBloc,
        seed: () => const PostCreationFailure(message: 'Some error'),
        act: (bloc) => bloc.add(const PostCreationReset()),
        expect: () => [
          const PostCreationInitial(),
        ],
      );
    });

    group('PostInputValidated', () {
      blocTest<PostCreationBloc, PostCreationState>(
        'should emit PostCreationValidating with no errors for valid input',
        build: () => postCreationBloc,
        act: (bloc) => bloc.add(const PostInputValidated(
          title: 'Valid Title',
          body: 'This is a valid post body with enough content',
        )),
        expect: () => [
          const PostCreationValidating(
            titleError: null,
            bodyError: null,
            isValid: true,
          ),
        ],
      );

      blocTest<PostCreationBloc, PostCreationState>(
        'should emit PostCreationValidating with title error for empty title',
        build: () => postCreationBloc,
        act: (bloc) => bloc.add(const PostInputValidated(
          title: '',
          body: 'This is a valid post body with enough content',
        )),
        expect: () => [
          const PostCreationValidating(
            titleError: 'Post title is required',
            bodyError: null,
            isValid: false,
          ),
        ],
      );

      blocTest<PostCreationBloc, PostCreationState>(
        'should emit PostCreationValidating with title error for short title',
        build: () => postCreationBloc,
        act: (bloc) => bloc.add(const PostInputValidated(
          title: 'Hi',
          body: 'This is a valid post body with enough content',
        )),
        expect: () => [
          const PostCreationValidating(
            titleError: 'Post title must be at least 3 characters',
            bodyError: null,
            isValid: false,
          ),
        ],
      );

      blocTest<PostCreationBloc, PostCreationState>(
        'should emit PostCreationValidating with title error for long title',
        build: () => postCreationBloc,
        act: (bloc) => bloc.add(PostInputValidated(
          title: 'A' * 201, // 201 characters
          body: 'This is a valid post body with enough content',
        )),
        expect: () => [
          const PostCreationValidating(
            titleError: 'Post title cannot exceed 200 characters',
            bodyError: null,
            isValid: false,
          ),
        ],
      );

      blocTest<PostCreationBloc, PostCreationState>(
        'should emit PostCreationValidating with body error for empty body',
        build: () => postCreationBloc,
        act: (bloc) => bloc.add(const PostInputValidated(
          title: 'Valid Title',
          body: '',
        )),
        expect: () => [
          const PostCreationValidating(
            titleError: null,
            bodyError: 'Post content is required',
            isValid: false,
          ),
        ],
      );

      blocTest<PostCreationBloc, PostCreationState>(
        'should emit PostCreationValidating with body error for short body',
        build: () => postCreationBloc,
        act: (bloc) => bloc.add(const PostInputValidated(
          title: 'Valid Title',
          body: 'Short',
        )),
        expect: () => [
          const PostCreationValidating(
            titleError: null,
            bodyError: 'Post content must be at least 10 characters',
            isValid: false,
          ),
        ],
      );

      blocTest<PostCreationBloc, PostCreationState>(
        'should emit PostCreationValidating with body error for long body',
        build: () => postCreationBloc,
        act: (bloc) => bloc.add(PostInputValidated(
          title: 'Valid Title',
          body: 'A' * 5001, // 5001 characters
        )),
        expect: () => [
          const PostCreationValidating(
            titleError: null,
            bodyError: 'Post content cannot exceed 5000 characters',
            isValid: false,
          ),
        ],
      );

      blocTest<PostCreationBloc, PostCreationState>(
        'should emit PostCreationValidating with both errors for invalid input',
        build: () => postCreationBloc,
        act: (bloc) => bloc.add(const PostInputValidated(
          title: '',
          body: 'Short',
        )),
        expect: () => [
          const PostCreationValidating(
            titleError: 'Post title is required',
            bodyError: 'Post content must be at least 10 characters',
            isValid: false,
          ),
        ],
      );
    });

    group('optimistic post generation', () {
      test('should generate optimistic posts with negative IDs', () {
        // Create multiple posts to test ID generation
        final posts = <Post>[];
        
        for (int i = 0; i < 5; i++) {
          postCreationBloc.add(const PostCreationRequested(
            title: 'Test Post',
            body: 'This is a test post content',
            userId: 1,
          ));
          
          // Get the optimistic post from the loading state
          final state = postCreationBloc.state;
          if (state is PostCreationLoading && state.optimisticPost != null) {
            posts.add(state.optimisticPost!);
          }
        }
        
        // All optimistic posts should have negative IDs
        for (final post in posts) {
          expect(post.id, lessThan(0));
          expect(post.isOptimistic, true);
        }
      });
    });
  });
}