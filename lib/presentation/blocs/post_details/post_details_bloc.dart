import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/result.dart';
import '../../../domain/entities/post.dart';
import '../../../domain/entities/comment.dart';
import '../../../domain/usecases/posts/get_post_details_usecase.dart';
import '../../../domain/usecases/comments/get_comments_usecase.dart';
import '../../../domain/usecases/favorites/toggle_favorite_usecase.dart';
import 'post_details_event.dart';
import 'post_details_state.dart';

class PostDetailsBloc extends Bloc<PostDetailsEvent, PostDetailsState> {
  final GetPostDetailsUseCase getPostDetailsUseCase;
  final GetCommentsUseCase getCommentsUseCase;
  final ToggleFavoriteUseCase toggleFavoriteUseCase;

  PostDetailsBloc({
    required this.getPostDetailsUseCase,
    required this.getCommentsUseCase,
    required this.toggleFavoriteUseCase,
  }) : super(const PostDetailsInitial()) {
    on<PostDetailsRequested>(_onPostDetailsRequested);
    on<FavoriteToggled>(_onFavoriteToggled);
    on<PostDetailsRetryRequested>(_onPostDetailsRetryRequested);
    on<PostDetailsRefreshed>(_onPostDetailsRefreshed);
  }

  Future<void> _onPostDetailsRequested(
    PostDetailsRequested event,
    Emitter<PostDetailsState> emit,
  ) async {
    emit(const PostDetailsLoading());

    try {
      Logger.info('Requesting post details for ID: ${event.postId} (forceRefresh: ${event.forceRefresh})');

      // Load post details and comments concurrently
      final results = await Future.wait([
        getPostDetailsUseCase(GetPostDetailsParams(
          id: event.postId,
          forceRefresh: event.forceRefresh,
        )),
        getCommentsUseCase(GetCommentsParams(
          postId: event.postId,
          forceRefresh: event.forceRefresh,
        )),
      ]);

      final postResult = results[0] as Result<Post>;
      final commentsResult = results[1] as Result<List<Comment>>;

      if (postResult.isSuccess && commentsResult.isSuccess) {
        final post = postResult.successValue!;
        final comments = commentsResult.successValue!;
        
        Logger.info('Post details loaded successfully: ${post.title} with ${comments.length} comments');
        
        emit(PostDetailsLoaded(
          post: post,
          comments: comments,
        ));
      } else {
        // Handle partial failures - prioritize post failure over comments failure
        final failure = postResult.isFailure 
            ? postResult.failureValue! 
            : commentsResult.failureValue!;
            
        Logger.error('Failed to load post details: ${failure.message}');
        emit(PostDetailsError(
          message: failure.message,
          details: failure.toString(),
          postId: event.postId,
        ));
      }
    } catch (e) {
      Logger.error('Unexpected error loading post details', e);
      emit(PostDetailsError(
        message: 'An unexpected error occurred while loading post details',
        postId: event.postId,
      ));
    }
  }

  Future<void> _onFavoriteToggled(
    FavoriteToggled event,
    Emitter<PostDetailsState> emit,
  ) async {
    final currentState = state;
    
    // Only handle favorite toggle if we're in a loaded state
    if (currentState is! PostDetailsLoaded) {
      return;
    }

    // Show loading state for favorite toggle
    emit(currentState.copyWith(isTogglingFavorite: true));

    try {
      Logger.info('Toggling favorite for post ${event.postId} to ${event.isFavorite}');

      final result = await toggleFavoriteUseCase(ToggleFavoriteParams(
        id: event.postId,
        isFavorite: event.isFavorite,
      ));

      if (result.isSuccess) {
        final updatedPost = result.successValue!;
        Logger.info('Favorite toggled successfully for post ${event.postId}');
        
        emit(currentState.copyWith(
          post: updatedPost,
          isTogglingFavorite: false,
        ));
      } else {
        final failure = result.failureValue!;
        Logger.error('Failed to toggle favorite: ${failure.message}');
        
        // Keep current state but stop loading
        emit(currentState.copyWith(isTogglingFavorite: false));
        
        // Could emit a temporary error state or show a snackbar
        // For now, we'll just log the error and keep the current state
      }
    } catch (e) {
      Logger.error('Unexpected error toggling favorite', e);
      
      // Keep current state but stop loading
      emit(currentState.copyWith(isTogglingFavorite: false));
    }
  }

  Future<void> _onPostDetailsRetryRequested(
    PostDetailsRetryRequested event,
    Emitter<PostDetailsState> emit,
  ) async {
    Logger.info('Retrying post details request for ID: ${event.postId}');
    
    // Retry by requesting post details again
    add(PostDetailsRequested(
      postId: event.postId,
      forceRefresh: true,
    ));
  }

  Future<void> _onPostDetailsRefreshed(
    PostDetailsRefreshed event,
    Emitter<PostDetailsState> emit,
  ) async {
    final currentState = state;
    
    // If we're in a loaded state, show refresh indicator
    if (currentState is PostDetailsLoaded) {
      emit(currentState.copyWith(isRefreshing: true));
    }

    try {
      Logger.info('Refreshing post details for ID: ${event.postId}');

      // Load post details and comments concurrently with force refresh
      final results = await Future.wait([
        getPostDetailsUseCase(GetPostDetailsParams(
          id: event.postId,
          forceRefresh: true,
        )),
        getCommentsUseCase(GetCommentsParams(
          postId: event.postId,
          forceRefresh: true,
        )),
      ]);

      final postResult = results[0] as Result<Post>;
      final commentsResult = results[1] as Result<List<Comment>>;

      if (postResult.isSuccess && commentsResult.isSuccess) {
        final post = postResult.successValue!;
        final comments = commentsResult.successValue!;
        
        Logger.info('Post details refreshed successfully');
        
        emit(PostDetailsLoaded(
          post: post,
          comments: comments,
          isRefreshing: false,
        ));
      } else {
        // Handle refresh failure
        final failure = postResult.isFailure 
            ? postResult.failureValue! 
            : commentsResult.failureValue!;
            
        Logger.error('Failed to refresh post details: ${failure.message}');
        
        // If we had data before, keep it and just stop refreshing
        if (currentState is PostDetailsLoaded) {
          emit(currentState.copyWith(isRefreshing: false));
        } else {
          emit(PostDetailsError(
            message: failure.message,
            details: failure.toString(),
            postId: event.postId,
          ));
        }
      }
    } catch (e) {
      Logger.error('Unexpected error refreshing post details', e);
      
      // If we had data before, keep it and just stop refreshing
      if (currentState is PostDetailsLoaded) {
        emit(currentState.copyWith(isRefreshing: false));
      } else {
        emit(PostDetailsError(
          message: 'An unexpected error occurred while refreshing post details',
          postId: event.postId,
        ));
      }
    }
  }
}