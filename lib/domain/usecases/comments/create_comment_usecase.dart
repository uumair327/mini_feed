import '../../../core/utils/result.dart';
import '../../../core/errors/failures.dart';
import '../../entities/comment.dart';
import '../../repositories/comment_repository.dart';
import '../base_usecase.dart';

/// Use case for creating a new comment on a post
/// 
/// Handles comment creation with validation and delegates to the repository
/// for the actual creation process.
class CreateCommentUseCase implements UseCase<Comment, CreateCommentParams> {
  final CommentRepository repository;

  const CreateCommentUseCase(this.repository);

  @override
  Future<Result<Comment>> call(CreateCommentParams params) async {
    // Validate post ID
    if (params.postId <= 0) {
      return failure(const ValidationFailure('Post ID must be greater than 0'));
    }

    // Validate input parameters
    if (params.name.trim().isEmpty) {
      return failure(const ValidationFailure('Name is required'));
    }
    
    if (params.email.trim().isEmpty) {
      return failure(const ValidationFailure('Email is required'));
    }
    
    if (params.body.trim().isEmpty) {
      return failure(const ValidationFailure('Comment content is required'));
    }
    
    if (params.name.trim().length < 2) {
      return failure(const ValidationFailure('Name must be at least 2 characters'));
    }
    
    if (params.body.trim().length < 5) {
      return failure(const ValidationFailure('Comment must be at least 5 characters'));
    }
    
    if (!_isValidEmail(params.email.trim())) {
      return failure(const ValidationFailure('Please enter a valid email address'));
    }
    
    if (params.name.length > 100) {
      return failure(const ValidationFailure('Name cannot exceed 100 characters'));
    }
    
    if (params.body.length > 1000) {
      return failure(const ValidationFailure('Comment cannot exceed 1000 characters'));
    }

    // Delegate to repository for creation
    return await repository.createComment(
      postId: params.postId,
      name: params.name.trim(),
      email: params.email.trim(),
      body: params.body.trim(),
    );
  }

  /// Validates email format using a simple regex
  bool _isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }
}

/// Parameters for the create comment use case
class CreateCommentParams {
  final int postId;
  final String name;
  final String email;
  final String body;

  const CreateCommentParams({
    required this.postId,
    required this.name,
    required this.email,
    required this.body,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CreateCommentParams &&
        other.postId == postId &&
        other.name == name &&
        other.email == email &&
        other.body == body;
  }

  @override
  int get hashCode => postId.hashCode ^ name.hashCode ^ email.hashCode ^ body.hashCode;

  @override
  String toString() => 'CreateCommentParams(postId: $postId, name: $name, email: $email, body: ${body.length} chars)';
}