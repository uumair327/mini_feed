import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/result.dart';
import '../../../domain/entities/post.dart';
import '../../../domain/usecases/posts/get_posts_usecase.dart';
import '../../../domain/usecases/posts/search_posts_usecase.dart';
import 'feed_event.dart';
import 'feed_state.dart';

class FeedBloc extends Bloc<FeedEvent, FeedState> {
  final GetPostsUseCase getPostsUseCase;
  final SearchPostsUseCase searchPostsUseCase;

  static const int _postsPerPage = 20;
  Timer? _searchDebounceTimer;
  String? _currentSearchQuery;

  FeedBloc({
    required this.getPostsUseCase,
    required this.searchPostsUseCase,
  }) : super(const FeedInitial()) {
    on<FeedRequested>(_onFeedRequested);
    on<FeedRefreshed>(_onFeedRefreshed);
    on<FeedLoadMore>(_onFeedLoadMore);
    on<FeedSearchChanged>(_onFeedSearchChanged);
    on<FeedSearchCleared>(_onFeedSearchCleared);
    on<FeedRetryRequested>(_onFeedRetryRequested);
  }

  @override
  Future<void> close() {
    _searchDebounceTimer?.cancel();
    return super.close();
  }

  Future<void> _onFeedRequested(
    FeedRequested event,
    Emitter<FeedState> emit,
  ) async {
    emit(const FeedLoading());

    try {
      Logger.info('Requesting feed data (forceRefresh: ${event.forceRefresh})');

      final result = await getPostsUseCase(GetPostsParams(
        page: 1,
        limit: _postsPerPage,
        forceRefresh: event.forceRefresh,
      ));

      if (result.isSuccess) {
        final posts = result.successValue!;
        Logger.info('Feed loaded successfully with ${posts.length} posts');

        if (posts.isEmpty) {
          emit(const FeedEmpty());
        } else {
          emit(FeedLoaded(
            posts: posts,
            hasReachedMax: posts.length < _postsPerPage,
            currentPage: 1,
          ));
        }
      } else {
        final failure = result.failureValue!;
        Logger.error('Failed to load feed: ${failure.message}');
        emit(FeedError(
          message: failure.message,
          details: failure.toString(),
        ));
      }
    } catch (e) {
      Logger.error('Unexpected error loading feed', e);
      emit(const FeedError(
        message: 'An unexpected error occurred while loading the feed',
      ));
    }
  }

  Future<void> _onFeedRefreshed(
    FeedRefreshed event,
    Emitter<FeedState> emit,
  ) async {
    final currentState = state;
    
    // If we're in a loaded state, show refresh indicator
    if (currentState is FeedLoaded) {
      emit(currentState.copyWith(isRefreshing: true));
    }

    try {
      Logger.info('Refreshing feed data');

      final result = await getPostsUseCase(const GetPostsParams(
        page: 1,
        limit: _postsPerPage,
        forceRefresh: true,
      ));

      if (result.isSuccess) {
        final posts = result.successValue!;
        Logger.info('Feed refreshed successfully with ${posts.length} posts');

        if (posts.isEmpty) {
          emit(const FeedEmpty());
        } else {
          emit(FeedLoaded(
            posts: posts,
            hasReachedMax: posts.length < _postsPerPage,
            currentPage: 1,
            isRefreshing: false,
          ));
        }
      } else {
        final failure = result.failureValue!;
        Logger.error('Failed to refresh feed: ${failure.message}');
        
        // If we had data before, keep it and just stop refreshing
        if (currentState is FeedLoaded) {
          emit(currentState.copyWith(isRefreshing: false));
        } else {
          emit(FeedError(
            message: failure.message,
            details: failure.toString(),
          ));
        }
      }
    } catch (e) {
      Logger.error('Unexpected error refreshing feed', e);
      
      // If we had data before, keep it and just stop refreshing
      if (currentState is FeedLoaded) {
        emit(currentState.copyWith(isRefreshing: false));
      } else {
        emit(const FeedError(
          message: 'An unexpected error occurred while refreshing the feed',
        ));
      }
    }
  }

  Future<void> _onFeedLoadMore(
    FeedLoadMore event,
    Emitter<FeedState> emit,
  ) async {
    final currentState = state;
    
    // Only load more if we're in a loaded state and not already loading
    if (currentState is! FeedLoaded || 
        currentState.hasReachedMax || 
        currentState.isLoadingMore) {
      return;
    }

    emit(currentState.copyWith(isLoadingMore: true));

    try {
      final nextPage = currentState.currentPage + 1;
      Logger.info('Loading more posts (page: $nextPage)');

      Result<List<Post>> result;
      
      // If we're searching, use search use case
      if (currentState.searchQuery != null && currentState.searchQuery!.isNotEmpty) {
        result = await searchPostsUseCase(SearchPostsParams(
          query: currentState.searchQuery!,
          page: nextPage,
          limit: _postsPerPage,
        ));
      } else {
        result = await getPostsUseCase(GetPostsParams(
          page: nextPage,
          limit: _postsPerPage,
        ));
      }

      if (result.isSuccess) {
        final newPosts = result.successValue!;
        Logger.info('Loaded ${newPosts.length} more posts');

        final allPosts = [...currentState.posts, ...newPosts];
        
        emit(currentState.copyWith(
          posts: allPosts,
          hasReachedMax: newPosts.length < _postsPerPage,
          isLoadingMore: false,
          currentPage: nextPage,
        ));
      } else {
        final failure = result.failureValue!;
        Logger.error('Failed to load more posts: ${failure.message}');
        
        // Keep current state but stop loading
        emit(currentState.copyWith(isLoadingMore: false));
      }
    } catch (e) {
      Logger.error('Unexpected error loading more posts', e);
      
      // Keep current state but stop loading
      emit(currentState.copyWith(isLoadingMore: false));
    }
  }

  Future<void> _onFeedSearchChanged(
    FeedSearchChanged event,
    Emitter<FeedState> emit,
  ) async {
    final query = event.query.trim();
    
    // Cancel previous search timer
    _searchDebounceTimer?.cancel();
    
    // If query is empty, clear search
    if (query.isEmpty) {
      add(const FeedSearchCleared());
      return;
    }

    // Set current search query for debouncing
    _currentSearchQuery = query;
    
    // Debounce search for 300ms using Future.delayed
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Check if this is still the current search query and we're not closed
    if (!emit.isDone && !isClosed && _currentSearchQuery == query) {
      await _performSearch(query, emit);
    }
  }

  Future<void> _performSearch(String query, Emitter<FeedState> emit) async {
    emit(const FeedLoading());

    try {
      Logger.info('Searching posts with query: "$query"');

      final result = await searchPostsUseCase(SearchPostsParams(
        query: query,
        page: 1,
        limit: _postsPerPage,
      ));

      if (result.isSuccess) {
        final posts = result.successValue!;
        Logger.info('Search completed with ${posts.length} results');

        if (posts.isEmpty) {
          emit(FeedEmpty(searchQuery: query));
        } else {
          emit(FeedLoaded(
            posts: posts,
            hasReachedMax: posts.length < _postsPerPage,
            searchQuery: query,
            currentPage: 1,
          ));
        }
      } else {
        final failure = result.failureValue!;
        Logger.error('Search failed: ${failure.message}');
        emit(FeedError(
          message: failure.message,
          details: failure.toString(),
        ));
      }
    } catch (e) {
      Logger.error('Unexpected error during search', e);
      emit(const FeedError(
        message: 'An unexpected error occurred while searching',
      ));
    }
  }

  Future<void> _onFeedSearchCleared(
    FeedSearchCleared event,
    Emitter<FeedState> emit,
  ) async {
    // Cancel any pending search
    _searchDebounceTimer?.cancel();
    
    Logger.info('Clearing search and loading all posts');
    
    // Load all posts again
    add(const FeedRequested());
  }

  Future<void> _onFeedRetryRequested(
    FeedRetryRequested event,
    Emitter<FeedState> emit,
  ) async {
    Logger.info('Retrying feed request');
    
    // Retry based on current state
    final currentState = state;
    if (currentState is FeedEmpty && currentState.searchQuery != null) {
      // Retry search
      add(FeedSearchChanged(query: currentState.searchQuery!));
    } else {
      // Retry normal feed load
      add(const FeedRequested());
    }
  }
}