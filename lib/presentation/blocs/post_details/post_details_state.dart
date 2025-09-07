import 'package:equatable/equatable.dart';
import 'package:mini_feed/domain/entities/comment.dart';
import 'package:mini_feed/domain/entities/post.dart';

abstract class PostDetailsState extends Equatable {
  const PostDetailsState();

  @override
  List<Object?> get props => [];
}

class PostDetailsInitial extends PostDetailsState {
  const PostDetailsInitial();
}

class PostDetailsLoading extends PostDetailsState {
  const PostDetailsLoading();
}

class PostDetailsLoaded extends PostDetailsState {
  final Post post;
  final List<Comment> comments;
  final bool isLoadingComments;

  const PostDetailsLoaded({
    required this.post,
    required this.comments,
    this.isLoadingComments = false,
  });

  PostDetailsLoaded copyWith({
    Post? post,
    List<Comment>? comments,
    bool? isLoadingComments,
  }) {
    return PostDetailsLoaded(
      post: post ?? this.post,
      comments: comments ?? this.comments,
      isLoadingComments: isLoadingComments ?? this.isLoadingComments,
    );
  }

  @override
  List<Object?> get props => [post, comments, isLoadingComments];
}

class PostDetailsError extends PostDetailsState {
  final String message;
  final String? details;

  const PostDetailsError({
    required this.message,
    this.details,
  });

  @override
  List<Object?> get props => [message, details];
}