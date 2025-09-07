import 'package:equatable/equatable.dart';

abstract class PostCreationEvent extends Equatable {
  const PostCreationEvent();

  @override
  List<Object?> get props => [];
}

/// Event to request post creation
class PostCreationRequested extends PostCreationEvent {
  final String title;
  final String body;
  final int userId;

  const PostCreationRequested({
    required this.title,
    required this.body,
    required this.userId,
  });

  @override
  List<Object?> get props => [title, body, userId];
}

/// Event to add an optimistic post to the feed
class OptimisticPostAdded extends PostCreationEvent {
  final String title;
  final String body;
  final int userId;

  const OptimisticPostAdded({
    required this.title,
    required this.body,
    required this.userId,
  });

  @override
  List<Object?> get props => [title, body, userId];
}

/// Event to rollback optimistic post creation on failure
class PostCreationRollback extends PostCreationEvent {
  final int optimisticPostId;
  final String errorMessage;

  const PostCreationRollback({
    required this.optimisticPostId,
    required this.errorMessage,
  });

  @override
  List<Object?> get props => [optimisticPostId, errorMessage];
}

/// Event to reset the post creation state
class PostCreationReset extends PostCreationEvent {
  const PostCreationReset();
}

/// Event to validate post input
class PostInputValidated extends PostCreationEvent {
  final String title;
  final String body;

  const PostInputValidated({
    required this.title,
    required this.body,
  });

  @override
  List<Object?> get props => [title, body];
}