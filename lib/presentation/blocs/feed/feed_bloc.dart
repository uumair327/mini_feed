import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mini_feed/core/utils/logger.dart';
import 'package:mini_feed/domain/usecases/posts/get_posts_usecase.dart';
import 'package:mini_feed/domain/usecases/posts/search_posts_usecase.dart';
import 'package:mini_feed/domain/usecases/favorites/toggle_favorite_usecase.dart';
import 'package:mini_feed/presentation/blocs/feed/feed_event.dart';
import 'package:mini_feed/presentation/blocs/feed/feed_state.dart';

class FeedBloc extends Bloc<FeedEvent, FeedState> {
  final GetPostsUseCase getPostsUseCase;
  final SearchPostsUseCase searchPostsUseCase;
  final ToggleFavoriteUseCase toggleFavoriteUseCase;

  static const int _postsPerPage = 20;
  int _currentPage = 1;
  Timer? _searchDebounceTimer;

  FeedBloc({
    required this.getPostsUseCase,
    required this.searchPostsUseCase,
    required this.toggleFavoriteUseCase,
  }) : super(const FeedInitial()) {
    on<FeedRequested>(_onFeedRequested);
    on<FeedRefreshed>(_onFeedRefreshed);
    on<FeedLoadMore>(_onFeedLoadMore);
    on<FeedSearchChanged>(_onFeedSearchChanged);
    on<FeedSearchCleared>(_onFeedSearchCleared);
    on<FeedPostToggleFavorite>(_onFeedPostToggleFavorite);
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
    _currentPage = 1;

    try {
      Logger.info('Loading feed posts (page: $_currentPage)');
      
      final result = await getPostsUseCase(GetPostsParams(
        page: _currentPage,
        limit: _postsPerPage,
        forceRefresh: event.forceRefresh,
      ));

      if (result.isSuccess) {
        final posts = result.data!;
        Logger.info('Loaded ${posts.length} posts');
        
        if (posts.isEmpty) {
          emit(const FeedEmpty());
        } else {
          emit(FeedLoaded(
            posts: posts,
            hasReachedMax: posts.length < _postsPerPage,
          ));
        }
      } else {
        final failure = result.error!;
        Logger.error('Failed to load posts: ${failure.message}', failure.details);
        emit(FeedError(
          message: failure.message,
          details: failure.details,
        ));
      }
    } catch (e) {
      Logger.error('Unexpected error loading posts', e);
      emit(const FeedError(
        message: 'An unexpected error occurred while loading posts',
      ));
    }
  }

  Future<void> _onFeedRefreshed(
    FeedRefreshed event,
    Emitter<FeedState> emit,
  ) async {
    _currentPage = 1;

    try {
      Logger.info('Refreshing feed posts');
      
      final result = await getPostsUseCase(GetPostsParams(
        page: _currentPage,
        limit: _postsPerPage,
        forceRefresh: true,
      ));

      if (result.isSuccess) {
        final posts = result.data!;
        Logger.info('Refreshed ${posts.length} posts');
        
        if (posts.isEmpty) {
          emit(const FeedEmpty());
        } else {
          emit(FeedLoaded(
            posts: posts,
            hasReachedMax: posts.length < _postsPerPage,
          ));
        }
      } else {
        final failure = result.error!;
        Logger.error('Failed to refresh posts: ${failure.message}', failure.details);
        
        // Keep existing posts if refresh fails
        if (state is FeedLoaded) {
          final currentState = state as FeedLoaded;
          emit(FeedError(
            message: failure.message,
            details: failure.details,
            cachedPosts: currentState.posts,
          ));
        } else {
          emit(FeedError(
            message: failure.message,
            details: failure.details,
          ));
        }
      }
    } catch (e) {
      Logger.error('Unexpected error refreshing posts', e);
      
      // Keep existing posts if refresh fails
      if (state is FeedLoaded) {
        final currentState = state as FeedLoaded;
        emit(FeedError(
          message: 'An unexpected error occurred while refreshing posts',
          cachedPosts: currentState.posts,
        ));
      } else {
        emit(const FeedError(
          message: 'An unexpected error occurred while refreshing posts',
        ));
      }
    }
  }

  Future<void> _onFeedLoadMore(
    FeedLoadMore event,
    Emitter<FeedState> emit,
  ) async {
    if (state is! FeedLoaded) return;
    
    final currentState = state as FeedLoaded;
    if (currentState.hasReachedMax || currentState.isLoadingMore) return;

    emit(currentState.copyWith(isLoadingMore: true));
    _currentPage++;

    try {
      Logger.info('Loading more posts (page: $_currentPage)');
      
      final result = await getPostsUseCase(GetPostsParams(
        page: _currentPage,
        limit: _postsPerPage,
      ));

      if (result.isSuccess) {
        final newPosts = result.data!;
        Logger.info('Loaded ${newPosts.length} more posts');
        
        final allPosts = [...currentState.posts, ...newPosts];
        
        emit(FeedLoaded(
          posts: allPosts,
          hasReachedMax: newPosts.length < _postsPerPage,
          isLoadingMore: false,
          searchQuery: currentState.searchQuery,
        ));
      } else {
        final failure = result.error!;
        Logger.error('Failed to load more posts: ${failure.message}', failure.details);
        
        emit(currentState.copyWith(isLoadingMore: false));
        _currentPage--; // Revert page increment
      }
    } catch (e) {
      Logger.error('Unexpected error loading more posts', e);
      emit(currentState.copyWith(isLoadingMore: false));
      _currentPage--; // Revert page increment
    }
  }

  void _onFeedSearchChanged(
    FeedSearchChanged event,
    Emitter<FeedState> emit,
  ) {
    _searchDebounceTimer?.cancel();
    
    if (event.query.trim().isEmpty) {
      add(const FeedSearchCleared());
      return;
    }

    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(event.query.trim(), emit);
    });
  }

  Future<void> _performSearch(
    String query,
    Emitter<FeedState> emit,
  ) async {
    emit(const FeedLoading());
    _currentPage = 1;

    try {
      Logger.info('Searching posts with query: $query');
      
      final result = await searchPostsUseCase(SearchPostsParams(
        query: query,
        page: _currentPage,
        limit: _postsPerPage,
      ));

      if (result.isSuccess) {
        final posts = result.data!;
        Logger.info('Found ${posts.length} posts for query: $query');
        
        if (posts.isEmpty) {
          emit(FeedEmpty(searchQuery: query));
        } else {
          emit(FeedLoaded(
            posts: posts,
            hasReachedMax: posts.length < _postsPerPage,
            searchQuery: query,
          ));
        }
      } else {
        final failure = result.error!;
        Logger.error('Search failed: ${failure.message}', failure.details);
        emit(FeedError(
          message: failure.message,
          details: failure.details,
        ));
      }
    } catch (e) {
      Logger.error('Unexpected error during search', e);
      emit(const FeedError(
        message: 'An unexpected error occurred during search',
      ));
    }
  }

  Future<void> _onFeedSearchCleared(
    FeedSearchCleared event,
    Emitter<FeedState> emit,
  ) async {
    _searchDebounceTimer?.cancel();
    Logger.info('Clearing search, loading regular feed');
    add(const FeedRequested());
  }

  Future<void> _onFeedPostToggleFavorite(
    FeedPostToggleFavorite event,
    Emitter<FeedState> emit,
  ) async {
    if (state is! FeedLoaded) return;
    
    final currentState = state as FeedLoaded;
    
    try {
      Logger.info('Toggling favorite for post ${event.postId}: ${event.isFavorite}');
      
      // Optimistic update
      final updatedPosts = currentState.posts.map((post) {
        if (post.id == event.postId) {
          return post.copyWith(isFavorite: event.isFavorite);
        }
        return post;
      }).toList();
      
      emit(currentState.copyWith(posts: updatedPosts));
      
      final result = await toggleFavoriteUseCase(ToggleFavoriteParams(
        postId: event.postId,
        isFavorite: event.isFavorite,
      ));

      if (result.isSuccess) {
        Logger.info('Successfully toggled favorite for post ${event.postId}');
        // The optimistic update is already applied
      } else {
        final failure = result.error!;
        Logger.error('Failed to toggle favorite: ${failure.message}', failure.details);
        
        // Revert optimistic update
        final revertedPosts = currentState.posts.map((post) {
          if (post.id == event.postId) {
            return post.copyWith(isFavorite: !event.isFavorite);
          }
          return post;
        }).toList();
        
        emit(currentState.copyWith(posts: revertedPosts));
      }
    } catch (e) {
      Logger.error('Unexpected error toggling favorite', e);
      
      // Revert optimistic update
      emit(currentState);
    }
  }
}