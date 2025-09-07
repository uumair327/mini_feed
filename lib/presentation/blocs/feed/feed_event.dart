import 'package:equatable/equatable.dart';

abstract class FeedEvent extends Equatable {
  const FeedEvent();

  @override
  List<Object?> get props => [];
}

/// Event to request initial feed data
class FeedRequested extends FeedEvent {
  final bool forceRefresh;

  const FeedRequested({
    this.forceRefresh = false,
  });

  @override
  List<Object?> get props => [forceRefresh];
}

/// Event to refresh feed data (pull-to-refresh)
class FeedRefreshed extends FeedEvent {
  const FeedRefreshed();
}

/// Event to load more posts (pagination)
class FeedLoadMore extends FeedEvent {
  const FeedLoadMore();
}

/// Event when search query changes
class FeedSearchChanged extends FeedEvent {
  final String query;

  const FeedSearchChanged({
    required this.query,
  });

  @override
  List<Object?> get props => [query];
}

/// Event to clear search and show all posts
class FeedSearchCleared extends FeedEvent {
  const FeedSearchCleared();
}

/// Event to retry after an error
class FeedRetryRequested extends FeedEvent {
  const FeedRetryRequested();
}