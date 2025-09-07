import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:mini_feed/core/errors/failures.dart';
import 'package:mini_feed/core/utils/result.dart';
import 'package:mini_feed/domain/entities/post.dart';
import 'package:mini_feed/domain/usecases/posts/get_posts_usecase.dart';
import 'package:mini_feed/domain/usecases/posts/search_posts_usecase.dart';
import 'package:mini_feed/presentation/blocs/feed/feed_bloc.dart';
import 'package:mini_feed/presentation/blocs/feed/feed_event.dart';
import 'package:mini_feed/presentation/blocs/feed/feed_state.dart';

class MockGetPostsUseCase extends Mock implements GetPostsUseCase {}
class MockSearchPostsUseCase extends Mock implements SearchPostsUseCase {}

void main() {
  group('FeedBloc', () {
    late FeedBloc feedBloc;
    late MockGetPostsUseCase mockGetPostsUseCase;
    late MockSearchPostsUseCase mockSearchPostsUseCase;

    setUpAll(() {
      registerFallbackValue(const GetPostsParams(page: 1, limit: 20));
      registerFallbackValue(const SearchPostsParams(query: '', page: 1, limit: 20));
    });

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

    const tPosts = [
      Post(
        id: 1,
        title: 'Test Post 1',
        body: 'Test body 1',
        userId: 1,
      ),
      Post(
        id: 2,
        title: 'Test Post 2',
        body: 'Test body 2',
        userId: 1,
      ),
    ];

    group('initial state', () {
      test('should have FeedInitial as initial state', () {
        expect(feedBloc.state, equals(const FeedInitial()));
      });
    });

    group('FeedRequested', () {
      blocTest<FeedBloc, FeedState>(
        'should emit [FeedLoading, FeedLoaded] when posts are loaded successfully',
        build: () {
          when(() => mockGetPostsUseCase(any()))
              .thenAnswer((_) async => success(tPosts));
          return feedBloc;
        },
        act: (bloc) => bloc.add(const FeedRequested()),
        expect: () => [
          const FeedLoading(),
          const FeedLoaded(
            posts: tPosts,
            hasReachedMax: true, // Less than 20 posts
            currentPage: 1,
          ),
        ],
        verify: (_) {
          verify(() => mockGetPostsUseCase(const GetPostsParams(
            page: 1,
            limit: 20,
            forceRefresh: false,
          ))).called(1);
        },
      );

      blocTest<FeedBloc, FeedState>(
        'should emit [FeedLoading, FeedEmpty] when no posts are returned',
        build: () {
          when(() => mockGetPostsUseCase(any()))
              .thenAnswer((_) async => success(<Post>[]));
          return feedBloc;
        },
        act: (bloc) => bloc.add(const FeedRequested()),
        expect: () => [
          const FeedLoading(),
          const FeedEmpty(),
        ],
      );

      blocTest<FeedBloc, FeedState>(
        'should emit [FeedLoading, FeedError] when use case fails',
        build: () {
          when(() => mockGetPostsUseCase(any()))
              .thenAnswer((_) async => failure(const NetworkFailure('Network error')));
          return feedBloc;
        },
        act: (bloc) => bloc.add(const FeedRequested()),
        expect: () => [
          const FeedLoading(),
          const FeedError(
            message: 'Network error',
            details: 'NetworkFailure(Network error)',
          ),
        ],
      );

      blocTest<FeedBloc, FeedState>(
        'should call use case with forceRefresh when requested',
        build: () {
          when(() => mockGetPostsUseCase(any()))
              .thenAnswer((_) async => success(tPosts));
          return feedBloc;
        },
        act: (bloc) => bloc.add(const FeedRequested(forceRefresh: true)),
        expect: () => [
          const FeedLoading(),
          const FeedLoaded(
            posts: tPosts,
            hasReachedMax: true,
            currentPage: 1,
          ),
        ],
        verify: (_) {
          verify(() => mockGetPostsUseCase(const GetPostsParams(
            page: 1,
            limit: 20,
            forceRefresh: true,
          ))).called(1);
        },
      );
    });

    group('FeedRefreshed', () {
      blocTest<FeedBloc, FeedState>(
        'should emit refreshing state when already loaded',
        build: () {
          when(() => mockGetPostsUseCase(any()))
              .thenAnswer((_) async => success(tPosts));
          return feedBloc;
        },
        seed: () => const FeedLoaded(
          posts: tPosts,
          currentPage: 1,
        ),
        act: (bloc) => bloc.add(const FeedRefreshed()),
        expect: () => [
          const FeedLoaded(
            posts: tPosts,
            currentPage: 1,
            isRefreshing: true,
          ),
          const FeedLoaded(
            posts: tPosts,
            hasReachedMax: true,
            currentPage: 1,
            isRefreshing: false,
          ),
        ],
        verify: (_) {
          verify(() => mockGetPostsUseCase(const GetPostsParams(
            page: 1,
            limit: 20,
            forceRefresh: true,
          ))).called(1);
        },
      );

      blocTest<FeedBloc, FeedState>(
        'should keep existing data when refresh fails',
        build: () {
          when(() => mockGetPostsUseCase(any()))
              .thenAnswer((_) async => failure(const NetworkFailure('Network error')));
          return feedBloc;
        },
        seed: () => const FeedLoaded(
          posts: tPosts,
          currentPage: 1,
        ),
        act: (bloc) => bloc.add(const FeedRefreshed()),
        expect: () => [
          const FeedLoaded(
            posts: tPosts,
            currentPage: 1,
            isRefreshing: true,
          ),
          const FeedLoaded(
            posts: tPosts,
            currentPage: 1,
            isRefreshing: false,
          ),
        ],
      );
    });

    group('FeedLoadMore', () {
      const tMorePosts = [
        Post(
          id: 3,
          title: 'Test Post 3',
          body: 'Test body 3',
          userId: 1,
        ),
        Post(
          id: 4,
          title: 'Test Post 4',
          body: 'Test body 4',
          userId: 1,
        ),
      ];

      blocTest<FeedBloc, FeedState>(
        'should load more posts and append to existing list',
        build: () {
          when(() => mockGetPostsUseCase(any()))
              .thenAnswer((_) async => success(tMorePosts));
          return feedBloc;
        },
        seed: () => const FeedLoaded(
          posts: tPosts,
          currentPage: 1,
        ),
        act: (bloc) => bloc.add(const FeedLoadMore()),
        expect: () => [
          const FeedLoaded(
            posts: tPosts,
            currentPage: 1,
            isLoadingMore: true,
          ),
          const FeedLoaded(
            posts: [...tPosts, ...tMorePosts],
            hasReachedMax: true, // Less than 20 new posts
            currentPage: 2,
            isLoadingMore: false,
          ),
        ],
        verify: (_) {
          verify(() => mockGetPostsUseCase(const GetPostsParams(
            page: 2,
            limit: 20,
          ))).called(1);
        },
      );

      blocTest<FeedBloc, FeedState>(
        'should not load more when already loading',
        build: () => feedBloc,
        seed: () => const FeedLoaded(
          posts: tPosts,
          currentPage: 1,
          isLoadingMore: true,
        ),
        act: (bloc) => bloc.add(const FeedLoadMore()),
        expect: () => [],
        verify: (_) {
          verifyNever(() => mockGetPostsUseCase(any()));
        },
      );

      blocTest<FeedBloc, FeedState>(
        'should not load more when reached max',
        build: () => feedBloc,
        seed: () => const FeedLoaded(
          posts: tPosts,
          currentPage: 1,
          hasReachedMax: true,
        ),
        act: (bloc) => bloc.add(const FeedLoadMore()),
        expect: () => [],
        verify: (_) {
          verifyNever(() => mockGetPostsUseCase(any()));
        },
      );

      blocTest<FeedBloc, FeedState>(
        'should use search use case when searching',
        build: () {
          when(() => mockSearchPostsUseCase(any()))
              .thenAnswer((_) async => success(tMorePosts));
          return feedBloc;
        },
        seed: () => const FeedLoaded(
          posts: tPosts,
          currentPage: 1,
          searchQuery: 'test',
        ),
        act: (bloc) => bloc.add(const FeedLoadMore()),
        expect: () => [
          const FeedLoaded(
            posts: tPosts,
            currentPage: 1,
            searchQuery: 'test',
            isLoadingMore: true,
          ),
          const FeedLoaded(
            posts: [...tPosts, ...tMorePosts],
            hasReachedMax: true,
            currentPage: 2,
            searchQuery: 'test',
            isLoadingMore: false,
          ),
        ],
        verify: (_) {
          verify(() => mockSearchPostsUseCase(const SearchPostsParams(
            query: 'test',
            page: 2,
            limit: 20,
          ))).called(1);
        },
      );
    });

    group('FeedSearchChanged', () {
      blocTest<FeedBloc, FeedState>(
        'should perform search after debounce delay',
        build: () {
          when(() => mockSearchPostsUseCase(any()))
              .thenAnswer((_) async => success(tPosts));
          return feedBloc;
        },
        act: (bloc) => bloc.add(const FeedSearchChanged(query: 'test')),
        wait: const Duration(milliseconds: 350), // Wait for debounce
        expect: () => [
          const FeedLoading(),
          const FeedLoaded(
            posts: tPosts,
            hasReachedMax: true,
            searchQuery: 'test',
            currentPage: 1,
          ),
        ],
        verify: (_) {
          verify(() => mockSearchPostsUseCase(const SearchPostsParams(
            query: 'test',
            page: 1,
            limit: 20,
          ))).called(1);
        },
      );

      blocTest<FeedBloc, FeedState>(
        'should emit empty state when search returns no results',
        build: () {
          when(() => mockSearchPostsUseCase(any()))
              .thenAnswer((_) async => success(<Post>[]));
          return feedBloc;
        },
        act: (bloc) => bloc.add(const FeedSearchChanged(query: 'nonexistent')),
        wait: const Duration(milliseconds: 350),
        expect: () => [
          const FeedLoading(),
          const FeedEmpty(searchQuery: 'nonexistent'),
        ],
      );

      blocTest<FeedBloc, FeedState>(
        'should clear search when query is empty',
        build: () {
          when(() => mockGetPostsUseCase(any()))
              .thenAnswer((_) async => success(tPosts));
          return feedBloc;
        },
        act: (bloc) => bloc.add(const FeedSearchChanged(query: '')),
        expect: () => [
          const FeedLoading(),
          const FeedLoaded(
            posts: tPosts,
            hasReachedMax: true,
            currentPage: 1,
          ),
        ],
        verify: (_) {
          verify(() => mockGetPostsUseCase(const GetPostsParams(
            page: 1,
            limit: 20,
            forceRefresh: false,
          ))).called(1);
        },
      );
    });

    group('FeedSearchCleared', () {
      blocTest<FeedBloc, FeedState>(
        'should load all posts when search is cleared',
        build: () {
          when(() => mockGetPostsUseCase(any()))
              .thenAnswer((_) async => success(tPosts));
          return feedBloc;
        },
        act: (bloc) => bloc.add(const FeedSearchCleared()),
        expect: () => [
          const FeedLoading(),
          const FeedLoaded(
            posts: tPosts,
            hasReachedMax: true,
            currentPage: 1,
          ),
        ],
      );
    });

    group('FeedRetryRequested', () {
      blocTest<FeedBloc, FeedState>(
        'should retry normal feed load from error state',
        build: () {
          when(() => mockGetPostsUseCase(any()))
              .thenAnswer((_) async => success(tPosts));
          return feedBloc;
        },
        seed: () => const FeedError(message: 'Network error'),
        act: (bloc) => bloc.add(const FeedRetryRequested()),
        expect: () => [
          const FeedLoading(),
          const FeedLoaded(
            posts: tPosts,
            hasReachedMax: true,
            currentPage: 1,
          ),
        ],
      );

      blocTest<FeedBloc, FeedState>(
        'should retry search from empty search state',
        build: () {
          when(() => mockSearchPostsUseCase(any()))
              .thenAnswer((_) async => success(tPosts));
          return feedBloc;
        },
        seed: () => const FeedEmpty(searchQuery: 'test'),
        act: (bloc) => bloc.add(const FeedRetryRequested()),
        wait: const Duration(milliseconds: 350), // Wait for search debounce
        expect: () => [
          const FeedLoading(),
          const FeedLoaded(
            posts: tPosts,
            hasReachedMax: true,
            searchQuery: 'test',
            currentPage: 1,
          ),
        ],
      );
    });

    group('edge cases', () {
      blocTest<FeedBloc, FeedState>(
        'should handle unexpected exceptions gracefully',
        build: () {
          when(() => mockGetPostsUseCase(any()))
              .thenThrow(Exception('Unexpected error'));
          return feedBloc;
        },
        act: (bloc) => bloc.add(const FeedRequested()),
        expect: () => [
          const FeedLoading(),
          const FeedError(
            message: 'An unexpected error occurred while loading the feed',
          ),
        ],
      );

      blocTest<FeedBloc, FeedState>(
        'should cancel previous search when new search is triggered',
        build: () {
          when(() => mockSearchPostsUseCase(any()))
              .thenAnswer((_) async => success(tPosts));
          return feedBloc;
        },
        act: (bloc) {
          bloc.add(const FeedSearchChanged(query: 'first'));
          bloc.add(const FeedSearchChanged(query: 'second'));
        },
        wait: const Duration(milliseconds: 350),
        expect: () => [
          const FeedLoading(),
          const FeedLoaded(
            posts: tPosts,
            hasReachedMax: true,
            searchQuery: 'second',
            currentPage: 1,
          ),
        ],
        verify: (_) {
          // Should only call search once for the final query
          verify(() => mockSearchPostsUseCase(const SearchPostsParams(
            query: 'second',
            page: 1,
            limit: 20,
          ))).called(1);
          verifyNever(() => mockSearchPostsUseCase(const SearchPostsParams(
            query: 'first',
            page: 1,
            limit: 20,
          )));
        },
      );
    });
  });
}