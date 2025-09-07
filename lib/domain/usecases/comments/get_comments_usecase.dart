import '../../../core/utils/result.dart';
import '../../../core/errors/failures.dart';
import '../../entities/comment.dart';
import '../../repositories/comment_repository.dart';
import '../base_usecase.dart';

/// Use case for retrieving comments for a specific post
/// 
/// Handles fetching comments from the repository with support for
/// pagination, caching, and force refresh functionality.
class GetCommentsUseCase implements UseCase<List<Comment>, GetCommentsParams> {
  final CommentRepository repository;

  const GetCommentsUseCase(this.repository);

  @override
  Future<Result<List<Comment>>> call(GetCommentsParams params) async {
    // Validate post ID
    if (params.postId <= 0) {
      return failure(const ValidationFailure('Post ID must be greater than 0'));
    }

    // Validate pagination parameters
    if (params.page != null && params.page! < 1) {
      return failure(const ValidationFailure('Page number must be greater than 0'));
    }
    
    if (params.limit != null && params.limit! < 1) {
      return failure(const ValidationFailure('Limit must be greater than 0'));
    }
    
    if (params.limit != null && params.limit! > 100) {
      return failure(const ValidationFailure('Limit cannot exceed 100 comments'));
    }

    // Delegate to repository
    return await repository.getComments(
      postId: params.postId,
      page: params.page ?? 1,
      limit: params.limit ?? 20,
      forceRefresh: params.forceRefresh,
    );
  }
}

/// Parameters for the get comments use case
class GetCommentsParams {
  final int postId;
  final int? page;
  final int? limit;
  final bool forceRefresh;

  const GetCommentsParams({
    required this.postId,
    this.page,
    this.limit,
    this.forceRefresh = false,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GetCommentsParams &&
        other.postId == postId &&
        other.page == page &&
        other.limit == limit &&
        other.forceRefresh == forceRefresh;
  }

  @override
  int get hashCode => postId.hashCode ^ page.hashCode ^ limit.hashCode ^ forceRefresh.hashCode;

  @override
  String toString() => 'GetCommentsParams(postId: $postId, page: $page, limit: $limit, forceRefresh: $forceRefresh)';
}