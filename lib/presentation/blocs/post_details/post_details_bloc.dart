import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mini_feed/core/utils/logger.dart';
import 'package:mini_feed/domain/usecases/posts/get_post_details_usecase.dart';
import 'package:mini_feed/domain/usecases/comments/get_comments_usecase.dart';
import 'package:mini_feed/domain/usecases/favorites/toggle_favorite_usecase.dart';
import 'package:mini_feed/presentation/blocs/post_details/post_details_event.dart';
import 'package:mini_feed/presentation/blocs/post_details/post_details_state.dart';

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
    on<PostDetailsFavoriteToggled>(_onPostDetailsFavoriteToggled);
  }

  Future<void> _onPostDetailsRequested(
    PostDetailsRequested event,
    Emitter<PostDetailsState> emit,
  ) async {
    emit(const PostDetailsLoading());

    try {
      Logger.info('Loading post details for post ${event.postId}');
      
      // Load post details
      final postResult = await getPostDetailsUseCase(GetPostDetailsParams(
        postId: event.postId,
        forceRefresh: event.forceRefresh,
      ));

      if (postResult.isFailure) {
        final failure = postResult.error!;
        Logger.error('Failed to load post details: ${failure.message}', failure.details);
        emit(PostDetailsError(
          message: failure.message,
          details: failure.details,
        ));
        return;
      }

      final post = postResult.data!;
      Logger.info('Loaded post details: ${post.title}');
      
      // Emit initial state with post but loading comments
      emit(PostDetailsLoaded(
        post: post,
        comments: const [],
        isLoadingComments: true,
      ));

      // Load comments
      Logger.info('Loading comments for post ${event.postId}');
      final commentsResult = await getCommentsUseCase(GetCommentsParams(
        postId: event.postId,
      ));

      if (commentsResult.isSuccess) {
        final comments = commentsResult.data!;
        Logger.info('Loaded ${comments.length} comments');
        
        emit(PostDetailsLoaded(
          post: post,
          comments: comments,
          isLoadingComments: false,
        ));
      } else {
        final failure = commentsResult.error!;
        Logger.error('Failed to load comments: ${failure.message}', failure.details);
        
        // Still show post even if comments fail to load
        emit(PostDetailsLoaded(
          post: post,
          comments: const [],
          isLoadingComments: false,
        ));
      }
    } catch (e) {
      Logger.error('Unexpected error loading post details', e);
      emit(const PostDetailsError(
        message: 'An unexpected error occurred while loading post details',
      ));
    }
  }

  Future<void> _onPostDetailsFavoriteToggled(
    PostDetailsFavoriteToggled event,
    Emitter<PostDetailsState> emit,
  ) async {
    if (state is! PostDetailsLoaded) return;
    
    final currentState = state as PostDetailsLoaded;
    
    try {
      Logger.info('Toggling favorite for post ${event.postId}: ${event.isFavorite}');
      
      // Optimistic update
      final updatedPost = currentState.post.copyWith(isFavorite: event.isFavorite);
      emit(currentState.copyWith(post: updatedPost));
      
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
        final revertedPost = currentState.post.copyWith(isFavorite: !event.isFavorite);
        emit(currentState.copyWith(post: revertedPost));
      }
    } catch (e) {
      Logger.error('Unexpected error toggling favorite', e);
      
      // Revert optimistic update
      emit(currentState);
    }
  }
}