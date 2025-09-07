import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mini_feed/core/errors/failures.dart';
import 'package:mini_feed/core/utils/result.dart';
import 'package:mini_feed/domain/entities/post.dart';
import 'package:mini_feed/domain/entities/comment.dart';
import 'package:mini_feed/domain/usecases/posts/get_post_details_usecase.dart';
import 'package:mini_feed/domain/usecases/comments/get_comments_usecase.dart';
import 'package:mini_feed/domain/usecases/favorites/toggle_favorite_usecase.dart';
import 'package:mini_feed/presentation/blocs/post_details/post_details_bloc.dart';
import 'package:mini_feed/presentation/blocs/post_details/post_details_event.dart';
import 'package:mini_feed/presentation/blocs/post_details/post_details_state.dart';

class MockGetPostDetailsUseCase extends Mock implements GetPostDetailsUseCase {}
class MockGetCommentsUseCase extends Mock implements GetCommentsUseCase {}
class MockToggleFavoriteUseCase extends Mock implements ToggleFavoriteUseCase {}

void main() {
  group('PostDetailsBloc', () {
    late PostDetailsBloc postDetailsBloc;
    late MockGetPostDetailsUseCase mockGetPostDetailsUseCase;
    late MockGetCommentsUseCase mockGetCommentsUseCase;
    late MockToggleFavoriteUseCase mockToggleFavoriteUseCase;

    setUpAll(() {
      registerFallbackValue(const GetPostDetailsParams(id: 1));
      registerFallbackValue(const GetCommentsParams(postId: 1));
      registerFallbackValue(const ToggleFavoriteParams(id: 1, isFavorite: true));
    });

    setUp(() {
      mockGetPostDetailsUseCase = MockGetPostDetailsUseCase();
      mockGetCommentsUseCase = MockGetCommentsUseCase();
      mockToggleFavoriteUseCase = MockToggleFavoriteUseCase();
      
      postDetailsBloc = PostDetailsBloc(
        getPostDetailsUseCase: mockGetPostDetailsUseCase,
        getCommentsUseCase: mockGetCommentsUseCase,
        toggleFavoriteUseCase: mockToggleFavoriteUseCase,
      );
    });

    tearDown(() {
      postDetailsBloc.close();
    });

    const tPost = Post(
      id: 1,
      title: 'Test Post',
      body: 'Test body content',
      userId: 1,
    );

    const tComments = [
      Comment(
        id: 1,
        postId: 1,
        name: 'Test Commenter',
        email: 'test@example.com',
        body: 'Test comment body',
      ),
      Comment(
        id: 2,
        postId: 1,
        name: 'Another Commenter',
        email: 'another@example.com',
        body: 'Another comment body',
      ),
    ];

    const tFavoritePost = Post(
      id: 1,
      title: 'Test Post',
      body: 'Test body content',
      userId: 1,
      isFavorite: true,
    );

    group('initial state', () {
      test('should have PostDetailsInitial as initial state', () {
        expect(postDetailsBloc.state, equals(const PostDetailsInitial()));
      });
    });

    group('PostDetailsRequested', () {
      blocTest<PostDetailsBloc, PostDetailsState>(
        'should emit [PostDetailsLoading, PostDetailsLoaded] when post and comments are loaded successfully',
        build: () {
          when(() => mockGetPostDetailsUseCase(any()))
              .thenAnswer((_) async => success(tPost));
          when(() => mockGetCommentsUseCase(any()))
              .thenAnswer((_) async => success(tComments));
          return postDetailsBloc;
        },
        act: (bloc) => bloc.add(const PostDetailsRequested(postId: 1)),
        expect: () => [
          const PostDetailsLoading(),
          const PostDetailsLoaded(
            post: tPost,
            comments: tComments,
          ),
        ],
        verify: (_) {
          verify(() => mockGetPostDetailsUseCase(const GetPostDetailsParams(
            id: 1,
            forceRefresh: false,
          ))).called(1);
          verify(() => mockGetCommentsUseCase(const GetCommentsParams(
            postId: 1,
            forceRefresh: false,
          ))).called(1);
        },
      );

      blocTest<PostDetailsBloc, PostDetailsState>(
        'should emit [PostDetailsLoading, PostDetailsError] when post loading fails',
        build: () {
          when(() => mockGetPostDetailsUseCase(any()))
              .thenAnswer((_) async => failure(const NetworkFailure('Network error')));
          when(() => mockGetCommentsUseCase(any()))
              .thenAnswer((_) async => success(tComments));
          return postDetailsBloc;
        },
        act: (bloc) => bloc.add(const PostDetailsRequested(postId: 1)),
        expect: () => [
          const PostDetailsLoading(),
          const PostDetailsError(
            message: 'Network error',
            details: 'NetworkFailure(Network error)',
            postId: 1,
          ),
        ],
      );

      blocTest<PostDetailsBloc, PostDetailsState>(
        'should emit [PostDetailsLoading, PostDetailsError] when comments loading fails',
        build: () {
          when(() => mockGetPostDetailsUseCase(any()))
              .thenAnswer((_) async => success(tPost));
          when(() => mockGetCommentsUseCase(any()))
              .thenAnswer((_) async => failure(const NetworkFailure('Comments error')));
          return postDetailsBloc;
        },
        act: (bloc) => bloc.add(const PostDetailsRequested(postId: 1)),
        expect: () => [
          const PostDetailsLoading(),
          const PostDetailsError(
            message: 'Comments error',
            details: 'NetworkFailure(Comments error)',
            postId: 1,
          ),
        ],
      );

      blocTest<PostDetailsBloc, PostDetailsState>(
        'should call use cases with forceRefresh when requested',
        build: () {
          when(() => mockGetPostDetailsUseCase(any()))
              .thenAnswer((_) async => success(tPost));
          when(() => mockGetCommentsUseCase(any()))
              .thenAnswer((_) async => success(tComments));
          return postDetailsBloc;
        },
        act: (bloc) => bloc.add(const PostDetailsRequested(
          postId: 1,
          forceRefresh: true,
        )),
        expect: () => [
          const PostDetailsLoading(),
          const PostDetailsLoaded(
            post: tPost,
            comments: tComments,
          ),
        ],
        verify: (_) {
          verify(() => mockGetPostDetailsUseCase(const GetPostDetailsParams(
            id: 1,
            forceRefresh: true,
          ))).called(1);
          verify(() => mockGetCommentsUseCase(const GetCommentsParams(
            postId: 1,
            forceRefresh: true,
          ))).called(1);
        },
      );
    });

    group('FavoriteToggled', () {
      blocTest<PostDetailsBloc, PostDetailsState>(
        'should toggle favorite successfully when in loaded state',
        build: () {
          when(() => mockToggleFavoriteUseCase(any()))
              .thenAnswer((_) async => success(tFavoritePost));
          return postDetailsBloc;
        },
        seed: () => const PostDetailsLoaded(
          post: tPost,
          comments: tComments,
        ),
        act: (bloc) => bloc.add(const FavoriteToggled(
          postId: 1,
          isFavorite: true,
        )),
        expect: () => [
          const PostDetailsLoaded(
            post: tPost,
            comments: tComments,
            isTogglingFavorite: true,
          ),
          const PostDetailsLoaded(
            post: tFavoritePost,
            comments: tComments,
            isTogglingFavorite: false,
          ),
        ],
        verify: (_) {
          verify(() => mockToggleFavoriteUseCase(const ToggleFavoriteParams(
            id: 1,
            isFavorite: true,
          ))).called(1);
        },
      );

      blocTest<PostDetailsBloc, PostDetailsState>(
        'should handle favorite toggle failure gracefully',
        build: () {
          when(() => mockToggleFavoriteUseCase(any()))
              .thenAnswer((_) async => failure(const NetworkFailure('Toggle failed')));
          return postDetailsBloc;
        },
        seed: () => const PostDetailsLoaded(
          post: tPost,
          comments: tComments,
        ),
        act: (bloc) => bloc.add(const FavoriteToggled(
          postId: 1,
          isFavorite: true,
        )),
        expect: () => [
          const PostDetailsLoaded(
            post: tPost,
            comments: tComments,
            isTogglingFavorite: true,
          ),
          const PostDetailsLoaded(
            post: tPost,
            comments: tComments,
            isTogglingFavorite: false,
          ),
        ],
      );

      blocTest<PostDetailsBloc, PostDetailsState>(
        'should not handle favorite toggle when not in loaded state',
        build: () => postDetailsBloc,
        seed: () => const PostDetailsLoading(),
        act: (bloc) => bloc.add(const FavoriteToggled(
          postId: 1,
          isFavorite: true,
        )),
        expect: () => [],
        verify: (_) {
          verifyNever(() => mockToggleFavoriteUseCase(any()));
        },
      );
    });

    group('PostDetailsRefreshed', () {
      blocTest<PostDetailsBloc, PostDetailsState>(
        'should emit refreshing state when already loaded',
        build: () {
          when(() => mockGetPostDetailsUseCase(any()))
              .thenAnswer((_) async => success(tPost));
          when(() => mockGetCommentsUseCase(any()))
              .thenAnswer((_) async => success(tComments));
          return postDetailsBloc;
        },
        seed: () => const PostDetailsLoaded(
          post: tPost,
          comments: tComments,
        ),
        act: (bloc) => bloc.add(const PostDetailsRefreshed(postId: 1)),
        expect: () => [
          const PostDetailsLoaded(
            post: tPost,
            comments: tComments,
            isRefreshing: true,
          ),
          const PostDetailsLoaded(
            post: tPost,
            comments: tComments,
            isRefreshing: false,
          ),
        ],
        verify: (_) {
          verify(() => mockGetPostDetailsUseCase(const GetPostDetailsParams(
            id: 1,
            forceRefresh: true,
          ))).called(1);
          verify(() => mockGetCommentsUseCase(const GetCommentsParams(
            postId: 1,
            forceRefresh: true,
          ))).called(1);
        },
      );

      blocTest<PostDetailsBloc, PostDetailsState>(
        'should keep existing data when refresh fails',
        build: () {
          when(() => mockGetPostDetailsUseCase(any()))
              .thenAnswer((_) async => failure(const NetworkFailure('Refresh failed')));
          when(() => mockGetCommentsUseCase(any()))
              .thenAnswer((_) async => success(tComments));
          return postDetailsBloc;
        },
        seed: () => const PostDetailsLoaded(
          post: tPost,
          comments: tComments,
        ),
        act: (bloc) => bloc.add(const PostDetailsRefreshed(postId: 1)),
        expect: () => [
          const PostDetailsLoaded(
            post: tPost,
            comments: tComments,
            isRefreshing: true,
          ),
          const PostDetailsLoaded(
            post: tPost,
            comments: tComments,
            isRefreshing: false,
          ),
        ],
      );

      blocTest<PostDetailsBloc, PostDetailsState>(
        'should emit error when refresh fails and no existing data',
        build: () {
          when(() => mockGetPostDetailsUseCase(any()))
              .thenAnswer((_) async => failure(const NetworkFailure('Refresh failed')));
          when(() => mockGetCommentsUseCase(any()))
              .thenAnswer((_) async => success(tComments));
          return postDetailsBloc;
        },
        act: (bloc) => bloc.add(const PostDetailsRefreshed(postId: 1)),
        expect: () => [
          const PostDetailsError(
            message: 'Refresh failed',
            details: 'NetworkFailure(Refresh failed)',
            postId: 1,
          ),
        ],
      );
    });

    group('PostDetailsRetryRequested', () {
      blocTest<PostDetailsBloc, PostDetailsState>(
        'should retry by requesting post details with force refresh',
        build: () {
          when(() => mockGetPostDetailsUseCase(any()))
              .thenAnswer((_) async => success(tPost));
          when(() => mockGetCommentsUseCase(any()))
              .thenAnswer((_) async => success(tComments));
          return postDetailsBloc;
        },
        act: (bloc) => bloc.add(const PostDetailsRetryRequested(postId: 1)),
        expect: () => [
          const PostDetailsLoading(),
          const PostDetailsLoaded(
            post: tPost,
            comments: tComments,
          ),
        ],
        verify: (_) {
          verify(() => mockGetPostDetailsUseCase(const GetPostDetailsParams(
            id: 1,
            forceRefresh: true,
          ))).called(1);
          verify(() => mockGetCommentsUseCase(const GetCommentsParams(
            postId: 1,
            forceRefresh: true,
          ))).called(1);
        },
      );
    });

    group('edge cases', () {
      blocTest<PostDetailsBloc, PostDetailsState>(
        'should handle unexpected exceptions gracefully',
        build: () {
          when(() => mockGetPostDetailsUseCase(any()))
              .thenThrow(Exception('Unexpected error'));
          return postDetailsBloc;
        },
        act: (bloc) => bloc.add(const PostDetailsRequested(postId: 1)),
        expect: () => [
          const PostDetailsLoading(),
          const PostDetailsError(
            message: 'An unexpected error occurred while loading post details',
            postId: 1,
          ),
        ],
      );

      blocTest<PostDetailsBloc, PostDetailsState>(
        'should handle favorite toggle exception gracefully',
        build: () {
          when(() => mockToggleFavoriteUseCase(any()))
              .thenThrow(Exception('Toggle error'));
          return postDetailsBloc;
        },
        seed: () => const PostDetailsLoaded(
          post: tPost,
          comments: tComments,
        ),
        act: (bloc) => bloc.add(const FavoriteToggled(
          postId: 1,
          isFavorite: true,
        )),
        expect: () => [
          const PostDetailsLoaded(
            post: tPost,
            comments: tComments,
            isTogglingFavorite: true,
          ),
          const PostDetailsLoaded(
            post: tPost,
            comments: tComments,
            isTogglingFavorite: false,
          ),
        ],
      );
    });
  });
}