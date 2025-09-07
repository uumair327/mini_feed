import '../entities/post.dart';
import '../entities/comment.dart';
import '../../core/utils/result.dart';
import '../../core/errors/failures.dart';

/// Repository interface for post-related operations
/// 
/// This repository handles all post and comment operations including
/// fetching posts, creating posts, managing favorites, searching, and comments.
/// 
/// All methods return [Result] objects to handle success and failure cases
/// in a type-safe manner without throwing exceptions.
abstract class PostRepository {
  /// Get a paginated list of posts
  /// 
  /// Fetches posts with pagination support. Uses caching to provide
  /// offline access and improved performance.
  /// 
  /// **Parameters:**
  /// - [page]: Page number (1-based)
  /// - [limit]: Number of posts per page
  /// - [forceRefresh]: Whether to bypass cache and fetch from network
  /// 
  /// **Returns:**
  /// - [Result<List<Post>>]: Success with posts list or failure with error
  /// 
  /// **Possible Failures:**
  /// - [NetworkFailure]: When network request fails and no cache available
  /// - [ServerFailure]: When server returns an error
  /// - [CacheFailure]: When cache operations fail
  Future<Result<List<Post>>> getPosts({
    int page = 1,
    int limit = 20,
    bool forceRefresh = false,
  });

  /// Get a specific post by ID
  /// 
  /// Fetches detailed information for a single post.
  /// Uses caching for offline access.
  /// 
  /// **Parameters:**
  /// - [postId]: Unique identifier of the post
  /// - [forceRefresh]: Whether to bypass cache and fetch from network
  /// 
  /// **Returns:**
  /// - [Result<Post>]: Success with post or failure with error
  /// 
  /// **Possible Failures:**
  /// - [NetworkFailure]: When network request fails and no cache available
  /// - [ServerFailure]: When server returns an error
  /// - [NotFoundFailure]: When post doesn't exist
  /// - [CacheFailure]: When cache operations fail
  Future<Result<Post>> getPost({
    required int postId,
    bool forceRefresh = false,
  });

  /// Get comments for a specific post
  /// 
  /// Fetches all comments associated with a post.
  /// Uses caching for offline access.
  /// 
  /// **Parameters:**
  /// - [postId]: Unique identifier of the post
  /// - [forceRefresh]: Whether to bypass cache and fetch from network
  /// 
  /// **Returns:**
  /// - [Result<List<Comment>>]: Success with comments list or failure with error
  /// 
  /// **Possible Failures:**
  /// - [NetworkFailure]: When network request fails and no cache available
  /// - [ServerFailure]: When server returns an error
  /// - [CacheFailure]: When cache operations fail
  Future<Result<List<Comment>>> getComments({
    required int postId,
    bool forceRefresh = false,
  });

  /// Create a new post
  /// 
  /// Creates a new post with optimistic updates. The post is immediately
  /// added to the local cache and UI, then synchronized with the server.
  /// 
  /// **Parameters:**
  /// - [title]: Post title
  /// - [body]: Post content
  /// - [userId]: ID of the user creating the post
  /// 
  /// **Returns:**
  /// - [Result<Post>]: Success with created post or failure with error
  /// 
  /// **Possible Failures:**
  /// - [NetworkFailure]: When network request fails
  /// - [ServerFailure]: When server returns an error
  /// - [ValidationFailure]: When post data is invalid
  /// - [AuthFailure]: When user is not authenticated
  Future<Result<Post>> createPost({
    required String title,
    required String body,
    required int userId,
  });

  /// Search posts by query
  /// 
  /// Searches posts by title and content. Implements debouncing
  /// and local filtering for better performance.
  /// 
  /// **Parameters:**
  /// - [query]: Search query string
  /// - [page]: Page number for paginated results
  /// - [limit]: Number of results per page
  /// 
  /// **Returns:**
  /// - [Result<List<Post>>]: Success with matching posts or failure with error
  /// 
  /// **Possible Failures:**
  /// - [NetworkFailure]: When network request fails
  /// - [ServerFailure]: When server returns an error
  /// - [ValidationFailure]: When query is invalid
  Future<Result<List<Post>>> searchPosts({
    required String query,
    int page = 1,
    int limit = 20,
  });

  /// Toggle favorite status of a post
  /// 
  /// Adds or removes a post from the user's favorites.
  /// Uses optimistic updates for immediate UI feedback.
  /// 
  /// **Parameters:**
  /// - [postId]: Unique identifier of the post
  /// - [isFavorite]: New favorite status
  /// 
  /// **Returns:**
  /// - [Result<Post>]: Success with updated post or failure with error
  /// 
  /// **Possible Failures:**
  /// - [NetworkFailure]: When network request fails
  /// - [ServerFailure]: When server returns an error
  /// - [NotFoundFailure]: When post doesn't exist
  /// - [AuthFailure]: When user is not authenticated
  Future<Result<Post>> toggleFavorite({
    required int postId,
    required bool isFavorite,
  });

  /// Refresh posts data
  /// 
  /// Forces a refresh of posts data from the server and updates the cache.
  /// Useful for pull-to-refresh functionality.
  /// 
  /// **Parameters:**
  /// - [clearCache]: Whether to clear existing cache before refresh
  /// 
  /// **Returns:**
  /// - [Result<List<Post>>]: Success with refreshed posts or failure with error
  /// 
  /// **Possible Failures:**
  /// - [NetworkFailure]: When network request fails
  /// - [ServerFailure]: When server returns an error
  /// - [CacheFailure]: When cache operations fail
  Future<Result<List<Post>>> refreshPosts({
    bool clearCache = false,
  });

  /// Get user's favorite posts
  /// 
  /// Retrieves all posts marked as favorites by the current user.
  /// 
  /// **Parameters:**
  /// - [userId]: ID of the user
  /// - [page]: Page number for pagination
  /// - [limit]: Number of posts per page
  /// 
  /// **Returns:**
  /// - [Result<List<Post>>]: Success with favorite posts or failure with error
  /// 
  /// **Possible Failures:**
  /// - [NetworkFailure]: When network request fails and no cache available
  /// - [ServerFailure]: When server returns an error
  /// - [AuthFailure]: When user is not authenticated
  /// - [CacheFailure]: When cache operations fail
  Future<Result<List<Post>>> getFavoritePosts({
    required int userId,
    int page = 1,
    int limit = 20,
  });

  /// Delete a post
  /// 
  /// Removes a post from the server and local cache.
  /// Only the post author or admin can delete posts.
  /// 
  /// **Parameters:**
  /// - [postId]: Unique identifier of the post
  /// 
  /// **Returns:**
  /// - [Result<void>]: Success or failure with error
  /// 
  /// **Possible Failures:**
  /// - [NetworkFailure]: When network request fails
  /// - [ServerFailure]: When server returns an error
  /// - [NotFoundFailure]: When post doesn't exist
  /// - [AuthFailure]: When user is not authorized to delete
  Future<Result<void>> deletePost({
    required int postId,
  });

  /// Get posts by user
  /// 
  /// Retrieves all posts created by a specific user.
  /// 
  /// **Parameters:**
  /// - [userId]: ID of the user
  /// - [page]: Page number for pagination
  /// - [limit]: Number of posts per page
  /// 
  /// **Returns:**
  /// - [Result<List<Post>>]: Success with user's posts or failure with error
  /// 
  /// **Possible Failures:**
  /// - [NetworkFailure]: When network request fails and no cache available
  /// - [ServerFailure]: When server returns an error
  /// - [CacheFailure]: When cache operations fail
  Future<Result<List<Post>>> getPostsByUser({
    required int userId,
    int page = 1,
    int limit = 20,
  });
}