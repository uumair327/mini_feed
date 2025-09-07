import 'package:dio/dio.dart';
import '../../../core/network/network_client.dart';
import '../../../core/utils/result.dart';
import '../../../core/errors/exceptions.dart';
import '../../models/post_model.dart';
import '../../models/comment_model.dart';

/// Remote data source for post operations
/// 
/// Handles post-related API calls to JSONPlaceholder for posts, comments,
/// and related operations. Provides comprehensive error handling and response parsing.
abstract class PostRemoteDataSource {
  /// Get paginated list of posts
  Future<Result<List<PostModel>>> getPosts({
    int page = 1,
    int limit = 20,
  });

  /// Get a specific post by ID
  Future<Result<PostModel>> getPostById(int postId);

  /// Get posts by user ID
  Future<Result<List<PostModel>>> getPostsByUserId(int userId);

  /// Create a new post
  Future<Result<PostModel>> createPost({
    required String title,
    required String body,
    required int userId,
  });

  /// Update an existing post
  Future<Result<PostModel>> updatePost({
    required int postId,
    String? title,
    String? body,
  });

  /// Delete a post
  Future<Result<void>> deletePost(int postId);

  /// Get comments for a specific post
  Future<Result<List<CommentModel>>> getComments({
    required int postId,
    int page = 1,
    int limit = 20,
  });

  /// Create a new comment
  Future<Result<CommentModel>> createComment({
    required int postId,
    required String name,
    required String email,
    required String body,
  });

  /// Search posts by title or body
  Future<Result<List<PostModel>>> searchPosts({
    required String query,
    int page = 1,
    int limit = 20,
  });
}

/// Implementation of PostRemoteDataSource using JSONPlaceholder API
class PostRemoteDataSourceImpl implements PostRemoteDataSource {
  final NetworkClient networkClient;

  const PostRemoteDataSourceImpl(this.networkClient);

  @override
  Future<Result<List<PostModel>>> getPosts({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await networkClient.get(
        '/posts',
        queryParameters: {
          '_page': page,
          '_limit': limit,
        },
      );

      final List<dynamic> postsJson = response.data as List<dynamic>;
      final posts = postsJson
          .map((json) => PostModel.fromJsonPlaceholder(json as Map<String, dynamic>))
          .toList();

      return success(posts);
    } on DioException catch (e) {
      _handleApiError(e);
    } catch (e) {
      throw ServerException('Unexpected error getting posts: $e', 500);
    }
  }

  @override
  Future<Result<PostModel>> getPostById(int postId) async {
    try {
      final response = await networkClient.get('/posts/$postId');
      
      final postJson = response.data as Map<String, dynamic>;
      final post = PostModel.fromJsonPlaceholder(postJson);
      
      return success(post);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw const ServerException('Post not found', 404);
      }
      _handleApiError(e);
    } catch (e) {
      throw ServerException('Unexpected error getting post: $e', 500);
    }
  }

  @override
  Future<Result<List<PostModel>>> getPostsByUserId(int userId) async {
    try {
      final response = await networkClient.get(
        '/posts',
        queryParameters: {
          'userId': userId,
        },
      );

      final List<dynamic> postsJson = response.data as List<dynamic>;
      final posts = postsJson
          .map((json) => PostModel.fromJsonPlaceholder(json as Map<String, dynamic>))
          .toList();

      return success(posts);
    } on DioException catch (e) {
      _handleApiError(e);
    } catch (e) {
      throw ServerException('Unexpected error getting user posts: $e', 500);
    }
  }

  @override
  Future<Result<PostModel>> createPost({
    required String title,
    required String body,
    required int userId,
  }) async {
    try {
      final response = await networkClient.post(
        '/posts',
        data: {
          'title': title,
          'body': body,
          'userId': userId,
        },
      );

      final postJson = response.data as Map<String, dynamic>;
      final post = PostModel.fromJsonPlaceholder(postJson);
      
      return success(post);
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw const ServerException('Invalid post data', 400);
      }
      _handleApiError(e);
    } catch (e) {
      throw ServerException('Unexpected error creating post: $e', 500);
    }
  }

  @override
  Future<Result<PostModel>> updatePost({
    required int postId,
    String? title,
    String? body,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (title != null) data['title'] = title;
      if (body != null) data['body'] = body;

      final response = await networkClient.patch(
        '/posts/$postId',
        data: data,
      );

      final postJson = response.data as Map<String, dynamic>;
      final post = PostModel.fromJsonPlaceholder(postJson);
      
      return success(post);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw const ServerException('Post not found', 404);
      } else if (e.response?.statusCode == 400) {
        throw const ServerException('Invalid update data', 400);
      }
      _handleApiError(e);
    } catch (e) {
      throw ServerException('Unexpected error updating post: $e', 500);
    }
  }

  @override
  Future<Result<void>> deletePost(int postId) async {
    try {
      await networkClient.delete('/posts/$postId');
      return success(null);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw const ServerException('Post not found', 404);
      }
      _handleApiError(e);
    } catch (e) {
      throw ServerException('Unexpected error deleting post: $e', 500);
    }
  }

  @override
  Future<Result<List<CommentModel>>> getComments({
    required int postId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await networkClient.get(
        '/posts/$postId/comments',
        queryParameters: {
          '_page': page,
          '_limit': limit,
        },
      );

      final List<dynamic> commentsJson = response.data as List<dynamic>;
      final comments = commentsJson
          .map((json) => CommentModel.fromJsonPlaceholder(json as Map<String, dynamic>))
          .toList();

      return success(comments);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw const ServerException('Post not found', 404);
      }
      _handleApiError(e);
    } catch (e) {
      throw ServerException('Unexpected error getting comments: $e', 500);
    }
  }

  @override
  Future<Result<CommentModel>> createComment({
    required int postId,
    required String name,
    required String email,
    required String body,
  }) async {
    try {
      final response = await networkClient.post(
        '/comments',
        data: {
          'postId': postId,
          'name': name,
          'email': email,
          'body': body,
        },
      );

      final commentJson = response.data as Map<String, dynamic>;
      final comment = CommentModel.fromJsonPlaceholder(commentJson);
      
      return success(comment);
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        throw const ServerException('Invalid comment data', 400);
      }
      _handleApiError(e);
    } catch (e) {
      throw ServerException('Unexpected error creating comment: $e', 500);
    }
  }

  @override
  Future<Result<List<PostModel>>> searchPosts({
    required String query,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      // JSONPlaceholder doesn't have a search endpoint, so we'll get all posts
      // and filter them locally. In a real app, this would be server-side.
      final allPostsResult = await getPosts(page: 1, limit: 100);
      
      if (allPostsResult.isFailure) {
        return failure(allPostsResult.failureValue!);
      }

      final allPosts = allPostsResult.successValue!;
      final filteredPosts = allPosts.where((post) {
        final titleMatch = post.title.toLowerCase().contains(query.toLowerCase());
        final bodyMatch = post.body.toLowerCase().contains(query.toLowerCase());
        return titleMatch || bodyMatch;
      }).toList();

      // Apply pagination to filtered results
      final startIndex = (page - 1) * limit;
      final endIndex = startIndex + limit;
      
      final paginatedPosts = filteredPosts.length > startIndex
          ? filteredPosts.sublist(
              startIndex,
              endIndex > filteredPosts.length ? filteredPosts.length : endIndex,
            )
          : <PostModel>[];

      return success(paginatedPosts);
    } catch (e) {
      throw ServerException('Unexpected error searching posts: $e', 500);
    }
  }

  /// Handle API errors and convert to appropriate exceptions
  Never _handleApiError(DioException error) {
    final statusCode = error.response?.statusCode ?? 500;
    final message = error.response?.data?['message'] ?? 
                   error.response?.data?['error'] ?? 
                   error.message ?? 
                   'Unknown error';
    
    if (statusCode >= 500) {
      throw ServerException('Server error: $message', statusCode);
    } else if (statusCode == 404) {
      throw const ServerException('Resource not found', 404);
    } else if (statusCode == 401) {
      throw const ServerException('Unauthorized', 401);
    } else if (statusCode == 400) {
      throw ServerException('Bad request: $message', 400);
    } else if (statusCode == 403) {
      throw const ServerException('Forbidden', 403);
    } else {
      throw ServerException('API error: $message', statusCode);
    }
  }
}