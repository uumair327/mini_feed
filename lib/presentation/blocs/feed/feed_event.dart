import 'package:equatable/equatable.dart';

abstract class FeedEvent extends Equatable {
  const FeedEvent();

  @override
  List<Object?> get props => [];
}

class FeedRequested extends FeedEvent {
  final bool forceRefresh;

  const FeedRequested({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}

class FeedRefreshed extends FeedEvent {
  const FeedRefreshed();
}

class FeedLoadMore extends FeedEvent {
  const FeedLoadMore();
}

class FeedSearchChanged extends FeedEvent {
  final String query;

  const FeedSearchChanged({required this.query});

  @override
  List<Object?> get props => [query];
}

class FeedSearchCleared extends FeedEvent {
  const FeedSearchCleared();
}

class FeedPostToggleFavorite extends FeedEvent {
  final int postId;
  final bool isFavorite;

  const FeedPostToggleFavorite({
    required this.postId,
    required this.isFavorite,
  });

  @override
  List<Object?> get props => [postId, isFavorite];
}