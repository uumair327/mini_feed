import '../../../core/utils/result.dart';
import '../../../core/errors/failures.dart';
import '../../entities/post.dart';
import '../../repositories/post_repository.dart';
import '../base_usecase.dart';

/// Use case for retrieving favorite posts
/// 
/// Handles fetching all posts marked as favorites by the user
/// with support for pagination and caching.
class GetFavoritePostsUseCase implements UseCase<List<Post>, GetFavoritePostsParams> {
  final PostRepository repository;

  const GetFavoritePostsUseCase(this.repository);

  @override
  Future<Result<List<Post>>> call(GetFavoritePostsParams params) async {
    // Validate user ID
    if (params.userId <= 0) {
      return failure(const ValidationFailure('User ID must be greater than 0'));
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

    // Delegate to repository
    return await repository.getFavoritePosts(
      userId: params.userId,
      page: params.page ?? 1,
      limit: params.limit ?? 20,
    );
  }
}

/// Parameters for the get favorite posts use case
class GetFavoritePostsParams {
  final int userId;
  final int? page;
  final int? limit;

  const GetFavoritePostsParams({
    required this.userId,
    this.page,
    this.limit,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GetFavoritePostsParams &&
        other.userId == userId &&
        other.page == page &&
        other.limit == limit;
  }

  @override
  int get hashCode => userId.hashCode ^ page.hashCode ^ limit.hashCode;

  @override
  String toString() => 'GetFavoritePostsParams(userId: $userId, page: $page, limit: $limit)';
}