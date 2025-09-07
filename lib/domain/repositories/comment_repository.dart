import '../entities/comment.dart';
import '../../core/utils/result.dart';
import '../../core/errors/failures.dart';

/// Abstract repository interface for comment operations
abstract class CommentRepository {
  /// Get all comments for a specific post
  /// Returns [Result] containing list of [Comment] on success or [Failure] on error
  Future<Result<List<Comment>>> getComments({
    required int postId,
    int? page,
    int? limit,
    bool forceRefresh = false,
  });

  /// Get a specific comment by ID
  /// Returns [Result] containing [Comment] on success or [Failure] on error
  Future<Result<Comment>> getComment({
    required int id,
    bool forceRefresh = false,
  });

  /// Create a new comment on a post
  /// Returns [Result] containing created [Comment] on success or [Failure] on error
  Future<Result<Comment>> createComment({
    required int postId,
    required String name,
    required String email,
    required String body,
  });

  /// Update an existing comment
  /// Returns [Result] containing updated [Comment] on success or [Failure] on error
  Future<Result<Comment>> updateComment({
    required int id,
    String? name,
    String? email,
    String? body,
  });

  /// Delete a comment
  /// Returns [Result] containing void on success or [Failure] on error
  Future<Result<void>> deleteComment({
    required int id,
  });

  /// Get comments by a specific user (by email)
  /// Returns [Result] containing list of [Comment] on success or [Failure] on error
  Future<Result<List<Comment>>> getCommentsByUser({
    required String email,
    int? page,
    int? limit,
    bool forceRefresh = false,
  });

  /// Search comments by content
  /// Returns [Result] containing list of matching [Comment] on success or [Failure] on error
  Future<Result<List<Comment>>> searchComments({
    required String query,
    int? postId,
    int? page,
    int? limit,
  });

  /// Get cached comments for a post (offline support)
  /// Returns [Result] containing list of cached [Comment] on success or [Failure] on error
  Future<Result<List<Comment>>> getCachedComments({
    required int postId,
  });

  /// Get comments count for a specific post
  /// Returns [Result] containing total count on success or [Failure] on error
  Future<Result<int>> getCommentsCount({
    required int postId,
  });

  /// Check if there are more comments to load for a post (pagination)
  /// Returns true if more comments are available
  Future<bool> hasMoreComments({
    required int postId,
  });

  /// Refresh comments for a post (pull-to-refresh)
  /// Returns [Result] containing list of [Comment] on success or [Failure] on error
  Future<Result<List<Comment>>> refreshComments({
    required int postId,
  });

  /// Clear cached comments for a specific post
  /// Returns [Result] containing void on success or [Failure] on error
  Future<Result<void>> clearCacheForPost({
    required int postId,
  });

  /// Clear all cached comments
  /// Returns [Result] containing void on success or [Failure] on error
  Future<Result<void>> clearAllCache();

  /// Report a comment as inappropriate
  /// Returns [Result] containing void on success or [Failure] on error
  Future<Result<void>> reportComment({
    required int id,
    required String reason,
  });

  /// Get recent comments across all posts
  /// Returns [Result] containing list of recent [Comment] on success or [Failure] on error
  Future<Result<List<Comment>>> getRecentComments({
    int? limit,
    bool forceRefresh = false,
  });
}