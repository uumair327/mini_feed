import '../../../core/utils/result.dart';
import '../../../core/errors/failures.dart';
import '../../entities/post.dart';
import '../../repositories/post_repository.dart';
import '../base_usecase.dart';

/// Use case for refreshing posts
/// 
/// Handles the pull-to-refresh functionality by forcing a refresh
/// of posts from the remote data source.
class RefreshPostsUseCase implements NoParamsUseCase<List<Post>> {
  final PostRepository repository;

  const RefreshPostsUseCase(this.repository);

  @override
  Future<Result<List<Post>>> call() async {
    // Delegate to repository for refresh
    return await repository.refreshPosts();
  }
}