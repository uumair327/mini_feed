import 'package:equatable/equatable.dart';

abstract class PostDetailsEvent extends Equatable {
  const PostDetailsEvent();

  @override
  List<Object?> get props => [];
}

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

class PostDetailsFavoriteToggled extends PostDetailsEvent {
  final int postId;
  final bool isFavorite;

  const PostDetailsFavoriteToggled({
    required this.postId,
    required this.isFavorite,
  });

  @override
  List<Object?> get props => [postId, isFavorite];
}