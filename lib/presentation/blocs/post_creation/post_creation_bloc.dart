import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/logger.dart';
import '../../../core/utils/result.dart';
import '../../../domain/entities/post.dart';
import '../../../domain/usecases/posts/create_post_usecase.dart';
import 'post_creation_event.dart';
import 'post_creation_state.dart';

class PostCreationBloc extends Bloc<PostCreationEvent, PostCreationState> {
  final CreatePostUseCase createPostUseCase;
  final Random _random = Random();

  PostCreationBloc({
    required this.createPostUseCase,
  }) : super(const PostCreationInitial()) {
    on<PostCreationRequested>(_onPostCreationRequested);
    on<OptimisticPostAdded>(_onOptimisticPostAdded);
    on<PostCreationRollback>(_onPostCreationRollback);
    on<PostCreationReset>(_onPostCreationReset);
    on<PostInputValidated>(_onPostInputValidated);
  }

  Future<void> _onPostCreationRequested(
    PostCreationRequested event,
    Emitter<PostCreationState> emit,
  ) async {
    try {
      Logger.info('Creating post: "${event.title}" by user ${event.userId}');

      // First, create and emit optimistic post
      final optimisticPost = _createOptimisticPost(
        title: event.title,
        body: event.body,
        userId: event.userId,
      );

      emit(PostCreationLoading(optimisticPost: optimisticPost));

      // Attempt to create the post via API
      final result = await createPostUseCase(CreatePostParams(
        title: event.title,
        body: event.body,
        userId: event.userId,
      ));

      if (result.isSuccess) {
        final createdPost = result.successValue!;
        Logger.info('Post created successfully with ID: ${createdPost.id}');
        
        emit(PostCreationSuccess(
          createdPost: createdPost,
          previousOptimisticPost: optimisticPost,
        ));
      } else {
        final failure = result.failureValue!;
        Logger.error('Failed to create post: ${failure.message}');
        
        emit(PostCreationFailure(
          message: failure.message,
          details: failure.toString(),
          failedOptimisticPost: optimisticPost,
        ));
      }
    } catch (e) {
      Logger.error('Unexpected error creating post', e);
      emit(const PostCreationFailure(
        message: 'An unexpected error occurred while creating the post',
      ));
    }
  }

  Future<void> _onOptimisticPostAdded(
    OptimisticPostAdded event,
    Emitter<PostCreationState> emit,
  ) async {
    Logger.info('Adding optimistic post: "${event.title}"');

    final optimisticPost = _createOptimisticPost(
      title: event.title,
      body: event.body,
      userId: event.userId,
    );

    emit(PostCreationOptimistic(optimisticPost: optimisticPost));

    // Now trigger the actual creation
    add(PostCreationRequested(
      title: event.title,
      body: event.body,
      userId: event.userId,
    ));
  }

  Future<void> _onPostCreationRollback(
    PostCreationRollback event,
    Emitter<PostCreationState> emit,
  ) async {
    Logger.info('Rolling back optimistic post ${event.optimisticPostId}: ${event.errorMessage}');

    emit(PostCreationFailure(
      message: event.errorMessage,
      details: 'Optimistic post creation failed and was rolled back',
      canRetry: true,
    ));
  }

  Future<void> _onPostCreationReset(
    PostCreationReset event,
    Emitter<PostCreationState> emit,
  ) async {
    Logger.info('Resetting post creation state');
    emit(const PostCreationInitial());
  }

  Future<void> _onPostInputValidated(
    PostInputValidated event,
    Emitter<PostCreationState> emit,
  ) async {
    final titleError = _validateTitle(event.title);
    final bodyError = _validateBody(event.body);
    final isValid = titleError == null && bodyError == null;

    emit(PostCreationValidating(
      titleError: titleError,
      bodyError: bodyError,
      isValid: isValid,
    ));
  }

  /// Creates an optimistic post for immediate UI feedback
  Post _createOptimisticPost({
    required String title,
    required String body,
    required int userId,
  }) {
    // Generate a temporary negative ID for optimistic posts
    // This helps distinguish them from real posts
    final optimisticId = -(_random.nextInt(999999) + 1);
    
    return Post(
      id: optimisticId,
      title: title,
      body: body,
      userId: userId,
      isOptimistic: true,
    );
  }

  /// Validates post title
  String? _validateTitle(String title) {
    final trimmedTitle = title.trim();
    
    if (trimmedTitle.isEmpty) {
      return 'Post title is required';
    }
    
    if (trimmedTitle.length < 3) {
      return 'Post title must be at least 3 characters';
    }
    
    if (trimmedTitle.length > 200) {
      return 'Post title cannot exceed 200 characters';
    }
    
    return null;
  }

  /// Validates post body
  String? _validateBody(String body) {
    final trimmedBody = body.trim();
    
    if (trimmedBody.isEmpty) {
      return 'Post content is required';
    }
    
    if (trimmedBody.length < 10) {
      return 'Post content must be at least 10 characters';
    }
    
    if (trimmedBody.length > 5000) {
      return 'Post content cannot exceed 5000 characters';
    }
    
    return null;
  }
}