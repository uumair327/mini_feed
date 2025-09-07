import 'package:equatable/equatable.dart';
import '../../../domain/entities/post.dart';
import '../../../domain/entities/comment.dart';

abstract class PostDetailsState extends Equatable {
  const PostDetailsState();

  @override
  List<Object?> get props => [];
}

/// Initial state when post details is first created
class PostDetailsInitial extends PostDetailsState {
  const PostDetailsInitial();
}

/// Loading state for initial data load
class PostDetailsLoading extends PostDetailsState {
  const PostDetailsLoading();
}

/// State when post details and comments are successfully loaded
class PostDetailsLoaded extends PostDetailsState {
  final Post post;
  final List<Comment> comments;
  final bool isRefreshing;
  final bool isTogglingFavorite;

  const PostDetailsLoaded({
    required this.post,
    required this.comments,
    this.isRefreshing = false,
    this.isTogglingFavorite = false,
  });

  PostDetailsLoaded copyWith({
    Post? post,
    List<Comment>? comments,
    bool? isRefreshing,
    bool? isTogglingFavorite,
  }) {
    return PostDetailsLoaded(
      post: post ?? this.post,
      comments: comments ?? this.comments,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isTogglingFavorite: isTogglingFavorite ?? this.isTogglingFavorite,
    );
  }

  @override
  List<Object?> get props => [
        post,
        comments,
        isRefreshing,
        isTogglingFavorite,
      ];
}

/// State when an error occurs
class PostDetailsError extends PostDetailsState {
  final String message;
  final String? details;
  final bool canRetry;
  final int? postId;

  const PostDetailsError({
    required this.message,
    this.details,
    this.canRetry = true,
    this.postId,
  });

  @override
  List<Object?> get props => [message, details, canRetry, postId];
}