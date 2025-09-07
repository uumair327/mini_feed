import 'package:equatable/equatable.dart';
import '../../../domain/entities/post.dart';

abstract class PostCreationState extends Equatable {
  const PostCreationState();

  @override
  List<Object?> get props => [];
}

/// Initial state when post creation is first created
class PostCreationInitial extends PostCreationState {
  const PostCreationInitial();
}

/// State when validating post input
class PostCreationValidating extends PostCreationState {
  final String? titleError;
  final String? bodyError;
  final bool isValid;

  const PostCreationValidating({
    this.titleError,
    this.bodyError,
    this.isValid = false,
  });

  @override
  List<Object?> get props => [titleError, bodyError, isValid];
}

/// State when post creation is in progress
class PostCreationLoading extends PostCreationState {
  final Post? optimisticPost;

  const PostCreationLoading({
    this.optimisticPost,
  });

  @override
  List<Object?> get props => [optimisticPost];
}

/// State when post creation succeeds
class PostCreationSuccess extends PostCreationState {
  final Post createdPost;
  final Post? previousOptimisticPost;

  const PostCreationSuccess({
    required this.createdPost,
    this.previousOptimisticPost,
  });

  @override
  List<Object?> get props => [createdPost, previousOptimisticPost];
}

/// State when post creation fails
class PostCreationFailure extends PostCreationState {
  final String message;
  final String? details;
  final Post? failedOptimisticPost;
  final bool canRetry;

  const PostCreationFailure({
    required this.message,
    this.details,
    this.failedOptimisticPost,
    this.canRetry = true,
  });

  @override
  List<Object?> get props => [message, details, failedOptimisticPost, canRetry];
}

/// State when optimistic post is added but creation is still pending
class PostCreationOptimistic extends PostCreationState {
  final Post optimisticPost;

  const PostCreationOptimistic({
    required this.optimisticPost,
  });

  @override
  List<Object?> get props => [optimisticPost];
}