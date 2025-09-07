import 'package:equatable/equatable.dart';
import '../../../domain/entities/post.dart';

abstract class FeedState extends Equatable {
  const FeedState();

  @override
  List<Object?> get props => [];
}

/// Initial state when feed is first created
class FeedInitial extends FeedState {
  const FeedInitial();
}

/// Loading state for initial data load
class FeedLoading extends FeedState {
  const FeedLoading();
}

/// State when feed data is successfully loaded
class FeedLoaded extends FeedState {
  final List<Post> posts;
  final bool hasReachedMax;
  final bool isLoadingMore;
  final bool isRefreshing;
  final String? searchQuery;
  final int currentPage;

  const FeedLoaded({
    required this.posts,
    this.hasReachedMax = false,
    this.isLoadingMore = false,
    this.isRefreshing = false,
    this.searchQuery,
    this.currentPage = 1,
  });

  FeedLoaded copyWith({
    List<Post>? posts,
    bool? hasReachedMax,
    bool? isLoadingMore,
    bool? isRefreshing,
    String? searchQuery,
    int? currentPage,
  }) {
    return FeedLoaded(
      posts: posts ?? this.posts,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      searchQuery: searchQuery ?? this.searchQuery,
      currentPage: currentPage ?? this.currentPage,
    );
  }

  @override
  List<Object?> get props => [
        posts,
        hasReachedMax,
        isLoadingMore,
        isRefreshing,
        searchQuery,
        currentPage,
      ];
}

/// State when feed is empty (no posts)
class FeedEmpty extends FeedState {
  final String? searchQuery;

  const FeedEmpty({
    this.searchQuery,
  });

  @override
  List<Object?> get props => [searchQuery];
}

/// State when an error occurs
class FeedError extends FeedState {
  final String message;
  final String? details;
  final bool canRetry;

  const FeedError({
    required this.message,
    this.details,
    this.canRetry = true,
  });

  @override
  List<Object?> get props => [message, details, canRetry];
}