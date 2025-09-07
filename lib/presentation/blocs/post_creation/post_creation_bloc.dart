import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mini_feed/core/utils/logger.dart';
import 'package:mini_feed/domain/usecases/posts/create_post_usecase.dart';
import 'package:mini_feed/presentation/blocs/post_creation/post_creation_event.dart';
import 'package:mini_feed/presentation/blocs/post_creation/post_creation_state.dart';

class PostCreationBloc extends Bloc<PostCreationEvent, PostCreationState> {
  final CreatePostUseCase createPostUseCase;

  PostCreationBloc({
    required this.createPostUseCase,
  }) : super(const PostCreationInitial()) {
    on<PostCreationRequested>(_onPostCreationRequested);
    on<PostCreationReset>(_onPostCreationReset);
  }

  Future<void> _onPostCreationRequested(
    PostCreationRequested event,
    Emitter<PostCreationState> emit,
  ) async {
    emit(const PostCreationLoading());

    try {
      Logger.info('Creating new post: ${event.title}');
      
      final result = await createPostUseCase(CreatePostParams(
        title: event.title,
        body: event.body,
        userId: event.userId,
      ));

      if (result.isSuccess) {
        final post = result.data!;
        Logger.info('Successfully created post with ID: ${post.id}');
        emit(PostCreationSuccess(post: post));
      } else {
        final failure = result.error!;
        Logger.error('Failed to create post: ${failure.message}', failure.details);
        emit(PostCreationFailure(
          message: failure.message,
          details: failure.details,
        ));
      }
    } catch (e) {
      Logger.error('Unexpected error creating post', e);
      emit(const PostCreationFailure(
        message: 'An unexpected error occurred while creating the post',
      ));
    }
  }

  void _onPostCreationReset(
    PostCreationReset event,
    Emitter<PostCreationState> emit,
  ) {
    emit(const PostCreationInitial());
  }
}