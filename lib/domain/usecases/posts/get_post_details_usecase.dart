import '../../../core/utils/result.dart';
import '../../../core/errors/failures.dart';
import '../../entities/post.dart';
import '../../repositories/post_repository.dart';
import '../base_usecase.dart';

/// Use case for retrieving a specific post's details
/// 
/// Handles fetching a single post by ID from the repository
/// with support for caching and force refresh.
class GetPostDetailsUseCase implements UseCase<Post, GetPostDetailsParams> {
  final PostRepository repository;

  const GetPostDetailsUseCase(this.repository);

  @override
  Future<Result<Post>> call(GetPostDetailsParams params) async {
    // Validate post ID
    if (params.id <= 0) {
      return failure(const ValidationFailure('Post ID must be greater than 0'));
    }

    // Delegate to repository
    return await repository.getPost(
      postId: params.id,
      forceRefresh: params.forceRefresh,
    );
  }
}

/// Parameters for the get post details use case
class GetPostDetailsParams {
  final int id;
  final bool forceRefresh;

  const GetPostDetailsParams({
    required this.id,
    this.forceRefresh = false,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GetPostDetailsParams &&
        other.id == id &&
        other.forceRefresh == forceRefresh;
  }

  @override
  int get hashCode => id.hashCode ^ forceRefresh.hashCode;

  @override
  String toString() => 'GetPostDetailsParams(id: $id, forceRefresh: $forceRefresh)';
}