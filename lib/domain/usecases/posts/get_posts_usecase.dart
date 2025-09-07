import '../../../core/utils/result.dart';
import '../../../core/errors/failures.dart';
import '../../entities/post.dart';
import '../../repositories/post_repository.dart';
import '../base_usecase.dart';

/// Use case for retrieving posts with pagination
/// 
/// Handles fetching posts from the repository with support for
/// pagination, caching, and force refresh functionality.
class GetPostsUseCase implements UseCase<List<Post>, GetPostsParams> {
  final PostRepository repository;

  const GetPostsUseCase(this.repository);

  @override
  Future<Result<List<Post>>> call(GetPostsParams params) async {
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

    // Delegate to repository
    return await repository.getPosts(
      page: params.page ?? 1,
      limit: params.limit ?? 20,
      forceRefresh: params.forceRefresh,
    );
  }
}

/// Parameters for the get posts use case
class GetPostsParams {
  final int? page;
  final int? limit;
  final bool forceRefresh;

  const GetPostsParams({
    this.page,
    this.limit,
    this.forceRefresh = false,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GetPostsParams &&
        other.page == page &&
        other.limit == limit &&
        other.forceRefresh == forceRefresh;
  }

  @override
  int get hashCode => page.hashCode ^ limit.hashCode ^ forceRefresh.hashCode;

  @override
  String toString() => 'GetPostsParams(page: $page, limit: $limit, forceRefresh: $forceRefresh)';
}