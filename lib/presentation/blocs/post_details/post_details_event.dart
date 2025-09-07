import 'package:equatable/equatable.dart';

abstract class PostDetailsEvent extends Equatable {
  const PostDetailsEvent();

  @override
  List<Object?> get props => [];
}

/// Event to request post details and comments
class PostDetailsRequested extends PostDetailsEvent {
  final int postId;
  final bool forceRefresh;

  const PostDetailsRequested({
    required this.postId,
    this.forceRefresh = false,
  });

  @override
  List<Object?> get props => [postId, forceRefresh];
}

/// Event to toggle favorite status of the post
class FavoriteToggled extends PostDetailsEvent {
  final int postId;
  final bool isFavorite;

  const FavoriteToggled({
    required this.postId,
    required this.isFavorite,
  });

  @override
  List<Object?> get props => [postId, isFavorite];
}

/// Event to retry loading post details after an error
class PostDetailsRetryRequested extends PostDetailsEvent {
  final int postId;

  const PostDetailsRetryRequested({
    required this.postId,
  });

  @override
  List<Object?> get props => [postId];
}

/// Event to refresh post details and comments
class PostDetailsRefreshed extends PostDetailsEvent {
  final int postId;

  const PostDetailsRefreshed({
    required this.postId,
  });

  @override
  List<Object?> get props => [postId];
}