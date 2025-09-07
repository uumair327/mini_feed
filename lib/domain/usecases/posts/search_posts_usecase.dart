import '../../../core/utils/result.dart';
import '../../../core/errors/failures.dart';
import '../../entities/post.dart';
import '../../repositories/post_repository.dart';
import '../base_usecase.dart';

/// Use case for searching posts
/// 
/// Handles post search functionality with validation and delegates
/// to the repository for the actual search implementation.
class SearchPostsUseCase implements UseCase<List<Post>, SearchPostsParams> {
  final PostRepository repository;

  const SearchPostsUseCase(this.repository);

  @override
  Future<Result<List<Post>>> call(SearchPostsParams params) async {
    // Validate search query
    if (params.query.trim().isEmpty) {
      return failure(const ValidationFailure('Search query cannot be empty'));
    }
    
    if (params.query.trim().length < 2) {
      return failure(const ValidationFailure('Search query must be at least 2 characters'));
    }
    
    if (params.query.length > 100) {
      return failure(const ValidationFailure('Search query cannot exceed 100 characters'));
    }

    // Validate pagination parameters
    if (params.page != null && params.page! < 1) {
      return failure(const ValidationFailure('Page number must be greater than 0'));
    }
    
    if (params.limit != null && params.limit! < 1) {
      return failure(const ValidationFailure('Limit must be greater than 0'));
    }
    
    if (params.limit != null && params.limit! > 100) {
      return failure(const ValidationFailure('Limit cannot exceed 100 posts'));
    }

    // Delegate to repository for search
    return await repository.searchPosts(
      query: params.query.trim(),
      page: params.page ?? 1,
      limit: params.limit ?? 20,
    );
  }
}

/// Parameters for the search posts use case
class SearchPostsParams {
  final String query;
  final int? page;
  final int? limit;

  const SearchPostsParams({
    required this.query,
    this.page,
    this.limit,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SearchPostsParams &&
        other.query == query &&
        other.page == page &&
        other.limit == limit;
  }

  @override
  int get hashCode => query.hashCode ^ page.hashCode ^ limit.hashCode;

  @override
  String toString() => 'SearchPostsParams(query: $query, page: $page, limit: $limit)';
}