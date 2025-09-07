import 'package:hive/hive.dart';
import '../../../core/storage/storage_service.dart';
import '../../../core/utils/result.dart';
import '../../../core/errors/exceptions.dart';
import '../../models/post_model.dart';
import '../../models/comment_model.dart';
import '../../models/cached_post.dart';
import '../../models/cached_comment.dart';
import '../../models/favorite_post.dart';
import '../../models/cache_metadata.dart';

/// Local data source for post operations
/// 
/// Handles local storage and caching of posts data for offline access
/// and improved performance through caching strategies using Hive.
abstract class PostLocalDataSource {
  /// Initialize local storage
  Future<Result<void>> initialize();

  /// Cache posts data
  Future<Result<void>> cachePosts(List<PostModel> posts, {
    int? page,
    int? limit,
    int? userId,
  });

  /// Get cached posts
  Future<Result<List<PostModel>>> getCachedPosts({
    int? page,
    int? limit,
    int? userId,
  });

  /// Cache a single post
  Future<Result<void>> cachePost(PostModel post);

  /// Get a cached post by ID
  Future<Result<PostModel?>> getCachedPost(int postId);

  /// Cache comments for a post
  Future<Result<void>> cacheComments(int postId, List<CommentModel> comments);

  /// Get cached comments for a post
  Future<Result<List<CommentModel>>> getCachedComments(int postId);

  /// Cache search results
  Future<Result<void>> cacheSearchResults(String query, List<PostModel> posts);

  /// Get cached search results
  Future<Result<List<PostModel>?>> getCachedSearchResults(String query);

  /// Add post to favorites
  Future<Result<void>> addToFavorites(int postId, int userId);

  /// Remove post from favorites
  Future<Result<void>> removeFromFavorites(int postId, int userId);

  /// Check if post is in favorites
  Future<Result<bool>> isPostFavorite(int postId, int userId);

  /// Get all favorite posts
  Future<Result<List<PostModel>>> getFavoritePosts(int userId);

  /// Clear all posts cache
  Future<Result<void>> clearPostsCache();

  /// Clear expired posts cache
  Future<Result<void>> clearExpiredPostsCache();

  /// Get posts cache statistics
  Result<Map<String, dynamic>> getPostsCacheStats();
}

/// Implementation of PostLocalDataSource using Hive
class PostLocalDataSourceImpl implements PostLocalDataSource {
  final StorageService storageService;
  
  // Hive boxes
  Box<CachedPost>? _postsBox;
  Box<CachedComment>? _commentsBox;
  Box<FavoritePost>? _favoritesBox;
  Box<CacheMetadata>? _metadataBox;

  PostLocalDataSourceImpl({
    required this.storageService,
  });

  @override
  Future<Result<void>> initialize() async {
    try {
      // Register Hive adapters if not already registered
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(CachedPostAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(FavoritePostAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(CacheMetadataAdapter());
      }
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(CachedCommentAdapter());
      }

      // Open Hive boxes
      _postsBox = await Hive.openBox<CachedPost>('cached_posts');
      _commentsBox = await Hive.openBox<CachedComment>('cached_comments');
      _favoritesBox = await Hive.openBox<FavoritePost>('favorite_posts');
      _metadataBox = await Hive.openBox<CacheMetadata>('cache_metadata');

      return success(null);
    } catch (e) {
      throw CacheException('Failed to initialize local storage: $e');
    }
  }

  @override
  Future<Result<void>> cachePosts(List<PostModel> posts, {
    int? page,
    int? limit,
    int? userId,
  }) async {
    try {
      _ensureInitialized();

      // Generate cache key
      final key = _generateCacheKey('posts', page: page, limit: limit, userId: userId);

      // Cache individual posts
      for (final post in posts) {
        final cachedPost = CachedPost.fromModel(post);
        await _postsBox!.put(post.id, cachedPost);
      }

      // Store cache metadata
      final metadata = CacheMetadata.forPosts(
        key: key,
        maxAge: const Duration(minutes: 15),
        tags: {
          if (page != null) 'page': page,
          if (limit != null) 'limit': limit,
          if (userId != null) 'userId': userId,
        },
      );
      await _metadataBox!.put(key, metadata);

      return success(null);
    } catch (e) {
      throw CacheException('Failed to cache posts: $e');
    }
  }

  @override
  Future<Result<List<PostModel>>> getCachedPosts({
    int? page,
    int? limit,
    int? userId,
  }) async {
    try {
      _ensureInitialized();

      final key = _generateCacheKey('posts', page: page, limit: limit, userId: userId);
      final metadata = _metadataBox!.get(key);

      // Check if cache is valid
      if (metadata == null || metadata.isExpired) {
        return success(<PostModel>[]);
      }

      // Get posts from cache
      List<CachedPost> cachedPosts;
      if (userId != null) {
        // Filter by user ID
        cachedPosts = _postsBox!.values
            .where((post) => post.userId == userId)
            .toList();
      } else {
        // Get all posts
        cachedPosts = _postsBox!.values.toList();
      }

      // Apply pagination if specified
      if (page != null && limit != null) {
        final startIndex = (page - 1) * limit;
        final endIndex = startIndex + limit;
        if (startIndex < cachedPosts.length) {
          cachedPosts = cachedPosts.sublist(
            startIndex,
            endIndex > cachedPosts.length ? cachedPosts.length : endIndex,
          );
        } else {
          cachedPosts = [];
        }
      }

      // Convert to PostModel and filter out expired entries
      final posts = cachedPosts
          .where((cached) => !cached.isExpired(const Duration(minutes: 15)))
          .map((cached) => cached.toModel())
          .toList();

      // Update metadata access
      await _metadataBox!.put(key, metadata.updateAccess());

      return success(posts);
    } catch (e) {
      throw CacheException('Failed to get cached posts: $e');
    }
  }

  @override
  Future<Result<void>> cachePost(PostModel post) async {
    try {
      _ensureInitialized();

      final cachedPost = CachedPost.fromModel(post);
      await _postsBox!.put(post.id, cachedPost);

      return success(null);
    } catch (e) {
      throw CacheException('Failed to cache post: $e');
    }
  }

  @override
  Future<Result<PostModel?>> getCachedPost(int postId) async {
    try {
      _ensureInitialized();

      final cachedPost = _postsBox!.get(postId);
      if (cachedPost == null || cachedPost.isExpired(const Duration(minutes: 15))) {
        return success(null);
      }

      return success(cachedPost.toModel());
    } catch (e) {
      throw CacheException('Failed to get cached post: $e');
    }
  }

  @override
  Future<Result<void>> cacheComments(int postId, List<CommentModel> comments) async {
    try {
      _ensureInitialized();

      // Cache individual comments
      for (final comment in comments) {
        final cachedComment = CachedComment.fromModel(comment);
        await _commentsBox!.put('${postId}_${comment.id}', cachedComment);
      }

      // Store cache metadata
      final key = 'comments_$postId';
      final metadata = CacheMetadata.forComments(
        key: key,
        maxAge: const Duration(minutes: 10),
        tags: {'postId': postId},
      );
      await _metadataBox!.put(key, metadata);

      return success(null);
    } catch (e) {
      throw CacheException('Failed to cache comments: $e');
    }
  }

  @override
  Future<Result<List<CommentModel>>> getCachedComments(int postId) async {
    try {
      _ensureInitialized();

      final key = 'comments_$postId';
      final metadata = _metadataBox!.get(key);

      // Check if cache is valid
      if (metadata == null || metadata.isExpired) {
        return success(<CommentModel>[]);
      }

      // Get comments for the post
      final cachedComments = _commentsBox!.values
          .where((comment) => comment.postId == postId)
          .where((comment) => !comment.isExpired(const Duration(minutes: 10)))
          .toList();

      final comments = cachedComments.map((cached) => cached.toModel()).toList();

      // Update metadata access
      await _metadataBox!.put(key, metadata.updateAccess());

      return success(comments);
    } catch (e) {
      throw CacheException('Failed to get cached comments: $e');
    }
  }

  @override
  Future<Result<void>> cacheSearchResults(String query, List<PostModel> posts) async {
    try {
      _ensureInitialized();

      // Cache the posts first
      for (final post in posts) {
        await cachePost(post);
      }

      // Store search metadata
      final key = 'search_${query.hashCode}';
      final metadata = CacheMetadata.forSearch(
        key: key,
        query: query,
        maxAge: const Duration(minutes: 5),
      );
      await _metadataBox!.put(key, metadata);

      // Store search result post IDs
      final postIds = posts.map((post) => post.id).toList();
      await storageService.setStringList(key, postIds.map((id) => id.toString()).toList());

      return success(null);
    } catch (e) {
      throw CacheException('Failed to cache search results: $e');
    }
  }

  @override
  Future<Result<List<PostModel>?>> getCachedSearchResults(String query) async {
    try {
      _ensureInitialized();

      final key = 'search_${query.hashCode}';
      final metadata = _metadataBox!.get(key);

      // Check if cache is valid
      if (metadata == null || metadata.isExpired) {
        return success(null);
      }

      // Get search result post IDs
      final postIdStrings = await storageService.getStringList(key);
      if (postIdStrings == null) return success(null);

      final postIds = postIdStrings.map((id) => int.parse(id)).toList();

      // Get cached posts
      final posts = <PostModel>[];
      for (final postId in postIds) {
        final cachedPost = _postsBox!.get(postId);
        if (cachedPost != null && !cachedPost.isExpired(const Duration(minutes: 15))) {
          posts.add(cachedPost.toModel());
        }
      }

      // Update metadata access
      await _metadataBox!.put(key, metadata.updateAccess());

      return success(posts);
    } catch (e) {
      throw CacheException('Failed to get cached search results: $e');
    }
  }

  @override
  Future<Result<void>> addToFavorites(int postId, int userId) async {
    try {
      _ensureInitialized();

      final favorite = FavoritePost.create(postId: postId, userId: userId);
      await _favoritesBox!.put(favorite.uniqueKey, favorite);

      return success(null);
    } catch (e) {
      throw CacheException('Failed to add to favorites: $e');
    }
  }

  @override
  Future<Result<void>> removeFromFavorites(int postId, int userId) async {
    try {
      _ensureInitialized();

      final key = '${userId}_$postId';
      await _favoritesBox!.delete(key);

      return success(null);
    } catch (e) {
      throw CacheException('Failed to remove from favorites: $e');
    }
  }

  @override
  Future<Result<bool>> isPostFavorite(int postId, int userId) async {
    try {
      _ensureInitialized();

      final key = '${userId}_$postId';
      final favorite = _favoritesBox!.get(key);

      return success(favorite != null);
    } catch (e) {
      throw CacheException('Failed to check favorite status: $e');
    }
  }

  @override
  Future<Result<List<PostModel>>> getFavoritePosts(int userId) async {
    try {
      _ensureInitialized();

      // Get favorite post IDs for the user
      final favorites = _favoritesBox!.values
          .where((favorite) => favorite.userId == userId)
          .toList();

      // Get the actual posts
      final posts = <PostModel>[];
      for (final favorite in favorites) {
        final cachedPost = _postsBox!.get(favorite.postId);
        if (cachedPost != null && !cachedPost.isExpired(const Duration(minutes: 15))) {
          final post = cachedPost.toModel().copyWith(isFavorite: true);
          posts.add(post);
        }
      }

      return success(posts);
    } catch (e) {
      throw CacheException('Failed to get favorite posts: $e');
    }
  }

  @override
  Future<Result<void>> clearPostsCache() async {
    try {
      _ensureInitialized();

      await _postsBox!.clear();
      await _commentsBox!.clear();
      await _favoritesBox!.clear();
      await _metadataBox!.clear();

      return success(null);
    } catch (e) {
      throw CacheException('Failed to clear posts cache: $e');
    }
  }

  @override
  Future<Result<void>> clearExpiredPostsCache() async {
    try {
      _ensureInitialized();

      // Clear expired posts
      final expiredPostKeys = <dynamic>[];
      for (final entry in _postsBox!.toMap().entries) {
        if (entry.value.isExpired(const Duration(minutes: 15))) {
          expiredPostKeys.add(entry.key);
        }
      }
      await _postsBox!.deleteAll(expiredPostKeys);

      // Clear expired comments
      final expiredCommentKeys = <dynamic>[];
      for (final entry in _commentsBox!.toMap().entries) {
        if (entry.value.isExpired(const Duration(minutes: 10))) {
          expiredCommentKeys.add(entry.key);
        }
      }
      await _commentsBox!.deleteAll(expiredCommentKeys);

      // Clear expired metadata
      final expiredMetadataKeys = <dynamic>[];
      for (final entry in _metadataBox!.toMap().entries) {
        if (entry.value.isExpired) {
          expiredMetadataKeys.add(entry.key);
        }
      }
      await _metadataBox!.deleteAll(expiredMetadataKeys);

      return success(null);
    } catch (e) {
      throw CacheException('Failed to clear expired cache: $e');
    }
  }

  @override
  Result<Map<String, dynamic>> getPostsCacheStats() {
    try {
      _ensureInitialized();

      final stats = {
        'posts_count': _postsBox!.length,
        'comments_count': _commentsBox!.length,
        'favorites_count': _favoritesBox!.length,
        'metadata_count': _metadataBox!.length,
        'total_entries': _postsBox!.length + _commentsBox!.length + _favoritesBox!.length + _metadataBox!.length,
      };

      return success(stats);
    } catch (e) {
      throw CacheException('Failed to get cache stats: $e');
    }
  }

  // Private helper methods
  void _ensureInitialized() {
    if (_postsBox == null || _commentsBox == null || _favoritesBox == null || _metadataBox == null) {
      throw CacheException('Local storage not initialized. Call initialize() first.');
    }
  }

  String _generateCacheKey(String prefix, {
    int? page,
    int? limit,
    int? userId,
  }) {
    final keyParts = [prefix];
    if (page != null) keyParts.add('page_$page');
    if (limit != null) keyParts.add('limit_$limit');
    if (userId != null) keyParts.add('user_$userId');
    return keyParts.join('_');
  }
}