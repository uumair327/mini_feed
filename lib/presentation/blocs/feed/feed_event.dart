import 'package:equatable/equatable.dart';
import '../../../domain/entities/post.dart';

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

/// Event to add an optimistic post to the feed
class OptimisticPostAdded extends FeedEvent {
  final Post optimisticPost;

  const OptimisticPostAdded({
    required this.optimisticPost,
  });

  @override
  List<Object?> get props => [optimisticPost];
}

/// Event to replace optimistic post with real post
class OptimisticPostReplaced extends FeedEvent {
  final Post optimisticPost;
  final Post realPost;

  const OptimisticPostReplaced({
    required this.optimisticPost,
    required this.realPost,
  });

  @override
  List<Object?> get props => [optimisticPost, realPost];
}

/// Event to remove optimistic post on failure
class OptimisticPostRemoved extends FeedEvent {
  final Post optimisticPost;

  const OptimisticPostRemoved({
    required this.optimisticPost,
  });

  @override
  List<Object?> get props => [optimisticPost];
}