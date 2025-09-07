import '../../../core/utils/result.dart';
import '../../../core/errors/failures.dart';
import '../../entities/post.dart';
import '../../repositories/post_repository.dart';
import '../base_usecase.dart';

/// Use case for creating a new post
/// 
/// Handles post creation with validation and delegates to the repository
/// for the actual creation process, including optimistic updates.
class CreatePostUseCase implements UseCase<Post, CreatePostParams> {
  final PostRepository repository;

  const CreatePostUseCase(this.repository);

  @override
  Future<Result<Post>> call(CreatePostParams params) async {
    // Validate input parameters
    if (params.title.trim().isEmpty) {
      return failure(const ValidationFailure('Post title is required'));
    }
    
    if (params.body.trim().isEmpty) {
      return failure(const ValidationFailure('Post content is required'));
    }
    
    if (params.title.trim().length < 3) {
      return failure(const ValidationFailure('Post title must be at least 3 characters'));
    }
    
    if (params.body.trim().length < 10) {
      return failure(const ValidationFailure('Post content must be at least 10 characters'));
    }
    
    if (params.title.length > 200) {
      return failure(const ValidationFailure('Post title cannot exceed 200 characters'));
    }
    
    if (params.body.length > 5000) {
      return failure(const ValidationFailure('Post content cannot exceed 5000 characters'));
    }

    // Delegate to repository for creation
    return await repository.createPost(
      title: params.title.trim(),
      body: params.body.trim(),
      userId: params.userId,
    );
  }
}

/// Parameters for the create post use case
class CreatePostParams {
  final String title;
  final String body;
  final int userId;

  const CreatePostParams({
    required this.title,
    required this.body,
    required this.userId,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CreatePostParams &&
        other.title == title &&
        other.body == body;
  }

  @override
  int get hashCode => title.hashCode ^ body.hashCode;

  @override
  String toString() => 'CreatePostParams(title: $title, body: ${body.length} chars)';
}