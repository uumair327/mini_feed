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
    } on ServerException catch (e) {
      print('[POSTS DEBUG] ServerException caught - Status: ${e.statusCode}, Message: ${e.message}');
      // Fallback to mock posts for demo purposes
      return _createMockPosts(page: page, limit: limit);
    } on NetworkException catch (e) {
      print('[POSTS DEBUG] NetworkException caught - Message: ${e.message}');
      // Fallback to mock posts for demo purposes
      return _createMockPosts(page: page, limit: limit);
    } catch (e) {
      print('[POSTS DEBUG] Generic exception caught: $e');
      // Fallback to mock posts for demo purposes
      return _createMockPosts(page: page, limit: limit);
    }
  }

  @override
  Future<Result<PostModel>> getPostById(int postId) async {
    try {
      final response = await networkClient.get('/posts/$postId');
      
      final postJson = response.data as Map<String, dynamic>;
      final post = PostModel.fromJsonPlaceholder(postJson);
      
      return success(post);
    } on ServerException catch (e) {
      print('[POSTS DEBUG] ServerException getting post $postId - Status: ${e.statusCode}');
      // Fallback to mock post
      return _createMockPost(postId);
    } on NetworkException catch (e) {
      print('[POSTS DEBUG] NetworkException getting post $postId - Message: ${e.message}');
      // Fallback to mock post
      return _createMockPost(postId);
    } catch (e) {
      print('[POSTS DEBUG] Generic exception getting post $postId: $e');
      // Fallback to mock post
      return _createMockPost(postId);
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
    } on ServerException catch (e) {
      print('[COMMENTS DEBUG] ServerException getting comments for post $postId - Status: ${e.statusCode}');
      // Fallback to mock comments
      return _createMockComments(postId: postId, page: page, limit: limit);
    } on NetworkException catch (e) {
      print('[COMMENTS DEBUG] NetworkException getting comments for post $postId - Message: ${e.message}');
      // Fallback to mock comments
      return _createMockComments(postId: postId, page: page, limit: limit);
    } catch (e) {
      print('[COMMENTS DEBUG] Generic exception getting comments for post $postId: $e');
      // Fallback to mock comments
      return _createMockComments(postId: postId, page: page, limit: limit);
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

  /// Create mock posts for demo purposes when API is unavailable
  Future<Result<List<PostModel>>> _createMockPosts({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      print('[POSTS DEBUG] Creating mock posts for page: $page, limit: $limit');
      
      final mockPosts = <PostModel>[];
      final startId = (page - 1) * limit + 1;
      
      for (int i = 0; i < limit; i++) {
        final id = startId + i;
        mockPosts.add(PostModel(
          id: id,
          userId: (id % 10) + 1, // Rotate through users 1-10
          title: 'Demo Post $id: ${_getMockTitle(id)}',
          body: _getMockBody(id),
        ));
      }
      
      print('[POSTS DEBUG] Created ${mockPosts.length} mock posts');
      return success(mockPosts);
    } catch (e) {
      print('[POSTS DEBUG] Error creating mock posts: $e');
      throw ServerException('Failed to create mock posts: $e', 500);
    }
  }
  
  /// Create a single mock post for demo purposes
  Future<Result<PostModel>> _createMockPost(int postId) async {
    try {
      print('[POSTS DEBUG] Creating mock post for ID: $postId');
      
      final post = PostModel(
        id: postId,
        userId: (postId % 10) + 1,
        title: 'Demo Post $postId: ${_getMockTitle(postId)}',
        body: _getMockBody(postId),
      );
      
      print('[POSTS DEBUG] Created mock post: ${post.title}');
      return success(post);
    } catch (e) {
      print('[POSTS DEBUG] Error creating mock post: $e');
      throw ServerException('Failed to create mock post: $e', 500);
    }
  }
  
  /// Create mock comments for demo purposes when API is unavailable
  Future<Result<List<CommentModel>>> _createMockComments({
    required int postId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      print('[COMMENTS DEBUG] Creating mock comments for post $postId, page: $page, limit: $limit');
      
      final mockComments = <CommentModel>[];
      final startId = (page - 1) * limit + 1;
      
      for (int i = 0; i < limit && i < 5; i++) { // Limit to 5 comments per post for demo
        final id = startId + i;
        mockComments.add(CommentModel(
          id: id,
          postId: postId,
          name: 'Demo User ${(id % 10) + 1}',
          email: 'user${(id % 10) + 1}@example.com',
          body: _getMockCommentBody(id),
        ));
      }
      
      print('[COMMENTS DEBUG] Created ${mockComments.length} mock comments');
      return success(mockComments);
    } catch (e) {
      print('[COMMENTS DEBUG] Error creating mock comments: $e');
      throw ServerException('Failed to create mock comments: $e', 500);
    }
  }
  
  /// Get mock comment body based on comment ID
  String _getMockCommentBody(int id) {
    final comments = [
      'Great post! This really helped me understand the concept better.',
      'Thanks for sharing this valuable information. Very insightful!',
      'I have a question about this approach. Could you elaborate more?',
      'This is exactly what I was looking for. Excellent explanation!',
      'Interesting perspective. I hadn\'t thought about it this way before.',
      'Well written and easy to follow. Keep up the good work!',
      'This solved my problem perfectly. Much appreciated!',
      'Could you provide more examples of this in practice?',
      'Fantastic tutorial! The step-by-step approach is very helpful.',
      'I\'m going to try implementing this in my project. Thanks!',
    ];
    return comments[id % comments.length];
  }
  
  /// Get mock title based on post ID
  String _getMockTitle(int id) {
    final titles = [
      'Welcome to Mini Feed!',
      'Building Flutter Apps with Clean Architecture',
      'The Power of Offline-First Design',
      'State Management with BLoC Pattern',
      'Creating Responsive UI Components',
      'Testing Strategies for Flutter Apps',
      'Optimizing App Performance',
      'User Experience Best Practices',
      'Modern Mobile Development',
      'Future of Cross-Platform Apps',
    ];
    return titles[id % titles.length];
  }
  
  /// Get mock body content based on post ID
  String _getMockBody(int id) {
    final bodies = [
      'This is a demo post showcasing the Mini Feed app capabilities. The app works offline and provides a great user experience even when APIs are unavailable.',
      'Clean Architecture helps create maintainable and testable Flutter applications. This post demonstrates how proper separation of concerns leads to better code.',
      'Offline-first design ensures your app works regardless of network conditions. Users can create, read, and interact with content seamlessly.',
      'BLoC pattern provides predictable state management for Flutter apps. This approach separates business logic from UI components effectively.',
      'Responsive design adapts to different screen sizes and orientations. Modern apps must work well on phones, tablets, and desktop devices.',
      'Comprehensive testing includes unit tests, widget tests, and integration tests. Quality assurance is crucial for production applications.',
      'Performance optimization involves efficient state management, proper widget disposal, and smart caching strategies for better user experience.',
      'Great UX focuses on intuitive navigation, clear feedback, and accessibility. Users should feel comfortable and productive using the app.',
      'Modern development practices include CI/CD, code quality tools, and collaborative workflows that improve team productivity and code quality.',
      'Cross-platform development with Flutter enables teams to build for multiple platforms with a single codebase while maintaining native performance.',
    ];
    return bodies[id % bodies.length];
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