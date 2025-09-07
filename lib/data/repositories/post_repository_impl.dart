import '../../core/network/network_info.dart';
import '../../core/storage/storage_service.dart';
import '../../core/utils/result.dart';
import '../../core/errors/failures.dart';
import '../../core/errors/exceptions.dart';
import '../../domain/entities/post.dart';
import '../../domain/entities/comment.dart';
import '../../domain/repositories/post_repository.dart';
import '../datasources/remote/post_remote_datasource.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';

/// Implementation of PostRepository
/// 
/// Handles post operations by coordinating between remote and local data sources.
/// Implements offline-first approach with caching and optimistic updates.
class PostRepositoryImpl implements PostRepository {
  final PostRemoteDataSource remoteDataSource;
  final StorageService storageService;
  final NetworkInfo networkInfo;

  const PostRepositoryImpl({
    required this.remoteDataSource,
    required this.storageService,
    required this.networkInfo,
  });

  @override
  Future<Result<List<Post>>> getPosts({
    int page = 1,
    int limit = 20,
    bool forceRefresh = false,
  }) async {
    try {
      final cacheKey = 'posts_${page}_$limit';
      
      // Try to get from cache first if not forcing refresh
      if (!forceRefresh) {
        final cachedPosts = await _getCachedPosts(cacheKey);
        if (cachedPosts.isNotEmpty) {
          return success(cachedPosts);
        }
      }

      // Check network connectivity
      if (!await networkInfo.isConnected) {
        final cachedPosts = await _getCachedPosts(cacheKey);
        if (cachedPosts.isNotEmpty) {
          return success(cachedPosts);
        }
        return failure(const NetworkFailure('No internet connection and no cached data'));
      }

      // Fetch from remote
      final remoteResult = await remoteDataSource.getPosts(page: page, limit: limit);
      if (remoteResult.isFailure) {
        return failure(remoteResult.failureValue!);
      }

      final postModels = remoteResult.successValue!;
      
      // Cache the results
      await _cachePosts(cacheKey, postModels);

      // Convert to domain entities and apply favorites
      final posts = await _applyFavoritesToPosts(postModels);
      return success(posts);
    } on ServerException catch (e) {
      return failure(ServerFailure(e.message, e.statusCode));
    } on NetworkException catch (e) {
      return failure(NetworkFailure(e.message));
    } on CacheException catch (e) {
      return failure(CacheFailure(e.message));
    } catch (e) {
      return failure(UnexpectedFailure('Failed to get posts: $e'));
    }
  }

  @override
  Future<Result<Post>> getPost({
    required int postId,
    bool forceRefresh = false,
  }) async {
    try {
      final cacheKey = 'post_$postId';
      
      // Try to get from cache first if not forcing refresh
      if (!forceRefresh) {
        final cachedPost = await _getCachedPost(cacheKey);
        if (cachedPost != null) {
          return success(cachedPost);
        }
      }

      // Check network connectivity
      if (!await networkInfo.isConnected) {
        final cachedPost = await _getCachedPost(cacheKey);
        if (cachedPost != null) {
          return success(cachedPost);
        }
        return failure(const NetworkFailure('No internet connection and no cached data'));
      }

      // Fetch from remote
      final remoteResult = await remoteDataSource.getPostById(postId);
      if (remoteResult.isFailure) {
        return failure(remoteResult.failureValue!);
      }

      final postModel = remoteResult.successValue!;
      
      // Cache the result
      await _cachePost(cacheKey, postModel);

      // Convert to domain entity and apply favorites
      final post = await _applyFavoritesToPost(postModel);
      return success(post);
    } on ServerException catch (e) {
      return failure(ServerFailure(e.message, e.statusCode));
    } on NetworkException catch (e) {
      return failure(NetworkFailure(e.message));
    } on CacheException catch (e) {
      return failure(CacheFailure(e.message));
    } catch (e) {
      return failure(UnexpectedFailure('Failed to get post: $e'));
    }
  }

  @override
  Future<Result<List<Comment>>> getComments({
    required int postId,
    bool forceRefresh = false,
  }) async {
    try {
      final cacheKey = 'comments_$postId';
      
      // Try to get from cache first if not forcing refresh
      if (!forceRefresh) {
        final cachedComments = await _getCachedComments(cacheKey);
        if (cachedComments.isNotEmpty) {
          return success(cachedComments);
        }
      }

      // Check network connectivity
      if (!await networkInfo.isConnected) {
        final cachedComments = await _getCachedComments(cacheKey);
        if (cachedComments.isNotEmpty) {
          return success(cachedComments);
        }
        return failure(const NetworkFailure('No internet connection and no cached data'));
      }

      // Fetch from remote
      final remoteResult = await remoteDataSource.getComments(postId: postId);
      if (remoteResult.isFailure) {
        return failure(remoteResult.failureValue!);
      }

      final commentModels = remoteResult.successValue!;
      
      // Cache the results
      await _cacheComments(cacheKey, commentModels);

      // Convert to domain entities
      final comments = commentModels.map((model) => model.toDomain()).toList();
      return success(comments);
    } on ServerException catch (e) {
      return failure(ServerFailure(e.message, e.statusCode));
    } on NetworkException catch (e) {
      return failure(NetworkFailure(e.message));
    } on CacheException catch (e) {
      return failure(CacheFailure(e.message));
    } catch (e) {
      return failure(UnexpectedFailure('Failed to get comments: $e'));
    }
  }

  @override
  Future<Result<Post>> createPost({
    required String title,
    required String body,
    required int userId,
  }) async {
    try {
      // Check network connectivity
      if (!await networkInfo.isConnected) {
        return failure(const NetworkFailure('No internet connection'));
      }

      // Create optimistic post
      final optimisticPost = PostModel(
        id: DateTime.now().millisecondsSinceEpoch, // Temporary ID
        title: title,
        body: body,
        userId: userId,
        isOptimistic: true,
      );

      // Add to cache immediately for optimistic update
      await _cachePost('post_${optimisticPost.id}', optimisticPost);

      // Create post on server
      final remoteResult = await remoteDataSource.createPost(
        title: title,
        body: body,
        userId: userId,
      );

      if (remoteResult.isFailure) {
        // Remove optimistic post from cache on failure
        await storageService.delete('post_${optimisticPost.id}');
        return failure(remoteResult.failureValue!);
      }

      final createdPost = remoteResult.successValue!;
      
      // Replace optimistic post with real post
      await storageService.delete('post_${optimisticPost.id}');
      await _cachePost('post_${createdPost.id}', createdPost);

      // Invalidate posts cache to force refresh
      await _invalidatePostsCache();

      return success(createdPost.toDomain());
    } on ServerException catch (e) {
      return failure(ServerFailure(e.message, e.statusCode));
    } on NetworkException catch (e) {
      return failure(NetworkFailure(e.message));
    } on CacheException catch (e) {
      return failure(CacheFailure(e.message));
    } catch (e) {
      return failure(UnexpectedFailure('Failed to create post: $e'));
    }
  }

  @override
  Future<Result<List<Post>>> searchPosts({
    required String query,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final cacheKey = 'search_${query.hashCode}_${page}_$limit';
      
      // Try to get from cache first
      final cachedPosts = await _getCachedPosts(cacheKey);
      if (cachedPosts.isNotEmpty) {
        return success(cachedPosts);
      }

      // Check network connectivity
      if (!await networkInfo.isConnected) {
        // Perform local search on cached posts
        final localResults = await _searchLocalPosts(query, page, limit);
        return success(localResults);
      }

      // Search on remote
      final remoteResult = await remoteDataSource.searchPosts(
        query: query,
        page: page,
        limit: limit,
      );

      if (remoteResult.isFailure) {
        return failure(remoteResult.failureValue!);
      }

      final postModels = remoteResult.successValue!;
      
      // Cache the results
      await _cachePosts(cacheKey, postModels);

      // Convert to domain entities and apply favorites
      final posts = await _applyFavoritesToPosts(postModels);
      return success(posts);
    } on ServerException catch (e) {
      return failure(ServerFailure(e.message, e.statusCode));
    } on NetworkException catch (e) {
      return failure(NetworkFailure(e.message));
    } on CacheException catch (e) {
      return failure(CacheFailure(e.message));
    } catch (e) {
      return failure(UnexpectedFailure('Failed to search posts: $e'));
    }
  }

  @override
  Future<Result<Post>> toggleFavorite({
    required int postId,
    required bool isFavorite,
  }) async {
    try {
      // Get current user ID (simplified - in real app would get from auth)
      const userId = 1; // This should come from authentication service

      // Update favorite status locally (optimistic update)
      if (isFavorite) {
        await _addToFavorites(postId, userId);
      } else {
        await _removeFromFavorites(postId, userId);
      }

      // Get the updated post
      final postResult = await getPost(postId: postId, forceRefresh: false);
      if (postResult.isFailure) {
        return failure(postResult.failureValue!);
      }

      return success(postResult.successValue!);
    } on CacheException catch (e) {
      return failure(CacheFailure(e.message));
    } catch (e) {
      return failure(UnexpectedFailure('Failed to toggle favorite: $e'));
    }
  }

  @override
  Future<Result<List<Post>>> refreshPosts({
    bool clearCache = false,
  }) async {
    try {
      if (clearCache) {
        await _clearPostsCache();
      }

      // Force refresh from remote
      return await getPosts(page: 1, limit: 20, forceRefresh: true);
    } catch (e) {
      return failure(UnexpectedFailure('Failed to refresh posts: $e'));
    }
  }

  @override
  Future<Result<List<Post>>> getFavoritePosts({
    required int userId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final favoritePosts = await _getFavoritePosts(userId);
      
      // Apply pagination
      final startIndex = (page - 1) * limit;
      final endIndex = startIndex + limit;
      
      final paginatedPosts = favoritePosts.length > startIndex
          ? favoritePosts.sublist(
              startIndex,
              endIndex > favoritePosts.length ? favoritePosts.length : endIndex,
            )
          : <Post>[];

      return success(paginatedPosts);
    } on CacheException catch (e) {
      return failure(CacheFailure(e.message));
    } catch (e) {
      return failure(UnexpectedFailure('Failed to get favorite posts: $e'));
    }
  }

  @override
  Future<Result<void>> deletePost({
    required int postId,
  }) async {
    try {
      // Check network connectivity
      if (!await networkInfo.isConnected) {
        return failure(const NetworkFailure('No internet connection'));
      }

      // Delete from remote
      final remoteResult = await remoteDataSource.deletePost(postId);
      if (remoteResult.isFailure) {
        return failure(remoteResult.failureValue!);
      }

      // Remove from cache
      await storageService.delete('post_$postId');
      await _invalidatePostsCache();

      return success(null);
    } on ServerException catch (e) {
      return failure(ServerFailure(e.message, e.statusCode));
    } on NetworkException catch (e) {
      return failure(NetworkFailure(e.message));
    } on CacheException catch (e) {
      return failure(CacheFailure(e.message));
    } catch (e) {
      return failure(UnexpectedFailure('Failed to delete post: $e'));
    }
  }

  @override
  Future<Result<List<Post>>> getPostsByUser({
    required int userId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final cacheKey = 'user_posts_${userId}_${page}_$limit';
      
      // Try to get from cache first
      final cachedPosts = await _getCachedPosts(cacheKey);
      if (cachedPosts.isNotEmpty) {
        return success(cachedPosts);
      }

      // Check network connectivity
      if (!await networkInfo.isConnected) {
        return failure(const NetworkFailure('No internet connection and no cached data'));
      }

      // Fetch from remote
      final remoteResult = await remoteDataSource.getPostsByUserId(userId);
      if (remoteResult.isFailure) {
        return failure(remoteResult.failureValue!);
      }

      final postModels = remoteResult.successValue!;
      
      // Apply pagination
      final startIndex = (page - 1) * limit;
      final endIndex = startIndex + limit;
      
      final paginatedModels = postModels.length > startIndex
          ? postModels.sublist(
              startIndex,
              endIndex > postModels.length ? postModels.length : endIndex,
            )
          : <PostModel>[];

      // Cache the results
      await _cachePosts(cacheKey, paginatedModels);

      // Convert to domain entities and apply favorites
      final posts = await _applyFavoritesToPosts(paginatedModels);
      return success(posts);
    } on ServerException catch (e) {
      return failure(ServerFailure(e.message, e.statusCode));
    } on NetworkException catch (e) {
      return failure(NetworkFailure(e.message));
    } on CacheException catch (e) {
      return failure(CacheFailure(e.message));
    } catch (e) {
      return failure(UnexpectedFailure('Failed to get posts by user: $e'));
    }
  }

  // Private helper methods

  Future<List<Post>> _getCachedPosts(String cacheKey) async {
    try {
      final cachedData = await storageService.get<String>(cacheKey);
      if (cachedData == null) return [];

      final cacheInfo = _parseCacheInfo(cachedData);
      if (_isCacheExpired(cacheInfo['timestamp'], const Duration(minutes: 15))) {
        return [];
      }

      final postIds = List<String>.from(cacheInfo['postIds'] ?? []);
      final posts = <Post>[];

      for (final postIdStr in postIds) {
        final postData = await storageService.get<String>('post_$postIdStr');
        if (postData != null) {
          final postModel = PostModel.fromJsonString(postData);
          final post = await _applyFavoritesToPost(postModel);
          posts.add(post);
        }
      }

      return posts;
    } catch (e) {
      return [];
    }
  }

  Future<Post?> _getCachedPost(String cacheKey) async {
    try {
      final cachedData = await storageService.get<String>(cacheKey);
      if (cachedData == null) return null;

      final postModel = PostModel.fromJsonString(cachedData);
      return await _applyFavoritesToPost(postModel);
    } catch (e) {
      return null;
    }
  }

  Future<List<Comment>> _getCachedComments(String cacheKey) async {
    try {
      final cachedData = await storageService.get<String>(cacheKey);
      if (cachedData == null) return [];

      final cacheInfo = _parseCacheInfo(cachedData);
      if (_isCacheExpired(cacheInfo['timestamp'], const Duration(minutes: 10))) {
        return [];
      }

      final commentIds = List<String>.from(cacheInfo['commentIds'] ?? []);
      final comments = <Comment>[];

      for (final commentIdStr in commentIds) {
        final commentData = await storageService.get<String>('comment_$commentIdStr');
        if (commentData != null) {
          final commentModel = CommentModel.fromJsonString(commentData);
          comments.add(commentModel.toDomain());
        }
      }

      return comments;
    } catch (e) {
      return [];
    }
  }

  Future<void> _cachePosts(String cacheKey, List<PostModel> posts) async {
    try {
      // Cache individual posts
      for (final post in posts) {
        await storageService.store('post_${post.id}', post.toJsonString());
      }

      // Cache the list metadata
      final cacheInfo = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'postIds': posts.map((p) => p.id.toString()).toList(),
      };
      await storageService.store(cacheKey, _encodeCacheInfo(cacheInfo));
    } catch (e) {
      throw CacheException('Failed to cache posts: $e');
    }
  }

  Future<void> _cachePost(String cacheKey, PostModel post) async {
    try {
      await storageService.store(cacheKey, post.toJsonString());
    } catch (e) {
      throw CacheException('Failed to cache post: $e');
    }
  }

  Future<void> _cacheComments(String cacheKey, List<CommentModel> comments) async {
    try {
      // Cache individual comments
      for (final comment in comments) {
        await storageService.store('comment_${comment.id}', comment.toJsonString());
      }

      // Cache the list metadata
      final cacheInfo = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'commentIds': comments.map((c) => c.id.toString()).toList(),
      };
      await storageService.store(cacheKey, _encodeCacheInfo(cacheInfo));
    } catch (e) {
      throw CacheException('Failed to cache comments: $e');
    }
  }

  Future<Post> _applyFavoritesToPost(PostModel postModel) async {
    try {
      const userId = 1; // This should come from authentication service
      final isFavorite = await _isPostFavorite(postModel.id, userId);
      return postModel.toDomain().copyWith(isFavorite: isFavorite);
    } catch (e) {
      return postModel.toDomain();
    }
  }

  Future<List<Post>> _applyFavoritesToPosts(List<PostModel> postModels) async {
    final posts = <Post>[];
    for (final postModel in postModels) {
      final post = await _applyFavoritesToPost(postModel);
      posts.add(post);
    }
    return posts;
  }

  Future<bool> _isPostFavorite(int postId, int userId) async {
    try {
      final favoriteKey = 'favorite_${userId}_$postId';
      final isFavorite = await storageService.get<bool>(favoriteKey);
      return isFavorite ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<void> _addToFavorites(int postId, int userId) async {
    try {
      final favoriteKey = 'favorite_${userId}_$postId';
      await storageService.store(favoriteKey, true);
    } catch (e) {
      throw CacheException('Failed to add to favorites: $e');
    }
  }

  Future<void> _removeFromFavorites(int postId, int userId) async {
    try {
      final favoriteKey = 'favorite_${userId}_$postId';
      await storageService.delete(favoriteKey);
    } catch (e) {
      throw CacheException('Failed to remove from favorites: $e');
    }
  }

  Future<List<Post>> _getFavoritePosts(int userId) async {
    try {
      // This is a simplified implementation
      // In a real app, you'd have a more efficient way to track favorites
      final posts = <Post>[];
      
      // Get all cached posts and filter favorites
      // This is not efficient but works for the demo
      for (int i = 1; i <= 100; i++) {
        final postData = await storageService.get<String>('post_$i');
        if (postData != null) {
          final isFavorite = await _isPostFavorite(i, userId);
          if (isFavorite) {
            final postModel = PostModel.fromJsonString(postData);
            final post = postModel.toDomain().copyWith(isFavorite: true);
            posts.add(post);
          }
        }
      }

      return posts;
    } catch (e) {
      return [];
    }
  }

  Future<List<Post>> _searchLocalPosts(String query, int page, int limit) async {
    try {
      final allPosts = <Post>[];
      
      // Get all cached posts
      for (int i = 1; i <= 100; i++) {
        final postData = await storageService.get<String>('post_$i');
        if (postData != null) {
          final postModel = PostModel.fromJsonString(postData);
          final post = await _applyFavoritesToPost(postModel);
          allPosts.add(post);
        }
      }

      // Filter by query
      final filteredPosts = allPosts.where((post) {
        final titleMatch = post.title.toLowerCase().contains(query.toLowerCase());
        final bodyMatch = post.body.toLowerCase().contains(query.toLowerCase());
        return titleMatch || bodyMatch;
      }).toList();

      // Apply pagination
      final startIndex = (page - 1) * limit;
      final endIndex = startIndex + limit;
      
      return filteredPosts.length > startIndex
          ? filteredPosts.sublist(
              startIndex,
              endIndex > filteredPosts.length ? filteredPosts.length : endIndex,
            )
          : <Post>[];
    } catch (e) {
      return [];
    }
  }

  Future<void> _clearPostsCache() async {
    try {
      // This is a simplified implementation
      // In a real app, you'd have a more efficient way to clear cache
      for (int i = 1; i <= 100; i++) {
        await storageService.delete('post_$i');
        await storageService.delete('comment_$i');
      }
    } catch (e) {
      throw CacheException('Failed to clear posts cache: $e');
    }
  }

  Future<void> _invalidatePostsCache() async {
    try {
      // Clear posts list caches
      for (int page = 1; page <= 10; page++) {
        await storageService.delete('posts_${page}_20');
      }
    } catch (e) {
      // Ignore cache invalidation errors
    }
  }

  Map<String, dynamic> _parseCacheInfo(String cacheData) {
    try {
      // Simple format: timestamp|postIds
      final parts = cacheData.split('|');
      if (parts.length >= 2) {
        return {
          'timestamp': int.parse(parts[0]),
          'postIds': parts[1].split(','),
        };
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  String _encodeCacheInfo(Map<String, dynamic> cacheInfo) {
    final timestamp = cacheInfo['timestamp'];
    final ids = (cacheInfo['postIds'] ?? cacheInfo['commentIds'] ?? []).join(',');
    return '$timestamp|$ids';
  }

  bool _isCacheExpired(int? timestamp, Duration maxAge) {
    if (timestamp == null) return true;
    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateTime.now().difference(cacheTime) > maxAge;
  }
}