import 'package:equatable/equatable.dart';
import 'package:mini_feed/domain/entities/post.dart';

abstract class FeedState extends Equatable {
  const FeedState();

  @override
  List<Object?> get props => [];
}

class FeedInitial extends FeedState {
  const FeedInitial();
}

class FeedLoading extends FeedState {
  const FeedLoading();
}

class FeedLoaded extends FeedState {
  final List<Post> posts;
  final bool hasReachedMax;
  final bool isLoadingMore;
  final String? searchQuery;

  const FeedLoaded({
    required this.posts,
    this.hasReachedMax = false,
    this.isLoadingMore = false,
    this.searchQuery,
  });

  FeedLoaded copyWith({
    List<Post>? posts,
    bool? hasReachedMax,
    bool? isLoadingMore,
    String? searchQuery,
  }) {
    return FeedLoaded(
      posts: posts ?? this.posts,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [posts, hasReachedMax, isLoadingMore, searchQuery];
}

class FeedEmpty extends FeedState {
  final String? searchQuery;

  const FeedEmpty({this.searchQuery});

  @override
  List<Object?> get props => [searchQuery];
}

class FeedError extends FeedState {
  final String message;
  final String? details;
  final List<Post>? cachedPosts;

  const FeedError({
    required this.message,
    this.details,
    this.cachedPosts,
  });

  @override
  List<Object?> get props => [message, details, cachedPosts];
}