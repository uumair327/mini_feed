import '../../../core/utils/result.dart';
import '../../../core/errors/failures.dart';
import '../../entities/comment.dart';
import '../../repositories/post_repository.dart';
import '../base_usecase.dart';

/// Use case for retrieving comments for a specific post
/// 
/// Handles fetching comments from the repository with support for
/// caching and force refresh functionality.
class GetCommentsUseCase implements UseCase<List<Comment>, GetCommentsParams> {
  final PostRepository repository;

  const GetCommentsUseCase(this.repository);

  @override
  Future<Result<List<Comment>>> call(GetCommentsParams params) async {
    // Validate post ID
    if (params.postId <= 0) {
      return failure(const ValidationFailure('Post ID must be greater than 0'));
    }

    // Delegate to repository
    return await repository.getComments(
      postId: params.postId,
      forceRefresh: params.forceRefresh,
    );
  }
}

/// Parameters for the get comments use case
class GetCommentsParams {
  final int postId;
  final bool forceRefresh;

  const GetCommentsParams({
    required this.postId,
    this.forceRefresh = false,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GetCommentsParams &&
        other.postId == postId &&
        other.forceRefresh == forceRefresh;
  }

  @override
  int get hashCode => postId.hashCode ^ forceRefresh.hashCode;

  @override
  String toString() => 'GetCommentsParams(postId: $postId, forceRefresh: $forceRefresh)';
}