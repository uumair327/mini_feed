import 'package:mini_feed/core/errors/failures.dart';
import 'package:mini_feed/core/utils/result.dart';
import 'package:mini_feed/data/datasources/local/post_local_datasource.dart';
import 'package:mini_feed/data/datasources/remote/post_remote_datasource.dart';
import 'package:mini_feed/domain/entities/comment.dart';
import 'package:mini_feed/domain/entities/post.dart';
import 'package:mini_feed/domain/repositories/post_repository.dart';

class PostRepositoryImpl implements PostRepository {
  final PostRemoteDataSource remoteDataSource;
  final PostLocalDataSource localDataSource;

  PostRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Result<List<Post>>> getPosts({
    bool forceRefresh = false,
    int limit = 20,
    int page = 1,
  }) async {
    try {
      if (!forceRefresh) {
        final cachedPosts = await localDataSource.getCachedPosts(
          limit: limit,
          page: page,
        );
        if (cachedPosts.isNotEmpty) {
          return Result.success(cachedPosts.map((p) => p.toEntity()).toList());
        }
      }

      final posts = await remoteDataSource.getPosts(limit: limit, page: page);
      await localDataSource.cachePosts(posts);
      return Result.success(posts.map((p) => p.toEntity()).toList());
    } catch (e) {
      return Result.failure(ServerFailure('Failed to get posts', e.toString()));
    }
  }

  @override
  Future<Result<Post>> getPost({
    required int postId,
    bool forceRefresh = false,
  }) async {
    try {
      if (!forceRefresh) {
        final cachedPost = await localDataSource.getCachedPost(postId);
        if (cachedPost != null) {
          return Result.success(cachedPost.toEntity());
        }
      }

      final post = await remoteDataSource.getPost(postId);
      await localDataSource.cachePost(post);
      return Result.success(post.toEntity());
    } catch (e) {
      return Result.failure(ServerFailure('Failed to get post', e.toString()));
    }
  }

  @override
  Future<Result<List<Post>>> getPostsByUser({
    required int userId,
    int limit = 20,
    int page = 1,
  }) async {
    try {
      final posts = await remoteDataSource.getPostsByUser(
        userId: userId,
        limit: limit,
        page: page,
      );
      return Result.success(posts.map((p) => p.toEntity()).toList());
    } catch (e) {
      return Result.failure(ServerFailure('Failed to get user posts', e.toString()));
    }
  }

  @override
  Future<Result<Post>> createPost({
    required String title,
    required String body,
    required int userId,
  }) async {
    try {
      final post = await remoteDataSource.createPost(
        title: title,
        body: body,
        userId: userId,
      );
      await localDataSource.cachePost(post);
      return Result.success(post.toEntity());
    } catch (e) {
      return Result.failure(ServerFailure('Failed to create post', e.toString()));
    }
  }

  @override
  Future<Result<Post>> updatePost({
    required int postId,
    required String title,
    required String body,
  }) async {
    try {
      final post = await remoteDataSource.updatePost(
        postId: postId,
        title: title,
        body: body,
      );
      await localDataSource.cachePost(post);
      return Result.success(post.toEntity());
    } catch (e) {
      return Result.failure(ServerFailure('Failed to update post', e.toString()));
    }
  }

  @override
  Future<Result<void>> deletePost({required int postId}) async {
    try {
      await remoteDataSource.deletePost(postId);
      await localDataSource.removeCachedPost(postId);
      return Result.success(null);
    } catch (e) {
      return Result.failure(ServerFailure('Failed to delete post', e.toString()));
    }
  }

  @override
  Future<Result<Post>> toggleFavorite({
    required int postId,
    required bool isFavorite,
  }) async {
    try {
      if (isFavorite) {
        await localDataSource.addToFavorites(postId);
      } else {
        await localDataSource.removeFromFavorites(postId);
      }
      
      final post = await localDataSource.getCachedPost(postId);
      if (post != null) {
        return Result.success(post.toEntity());
      }
      
      // Fallback to remote if not cached
      final remotePost = await remoteDataSource.getPost(postId);
      return Result.success(remotePost.toEntity());
    } catch (e) {
      return Result.failure(CacheFailure('Failed to toggle favorite', e.toString()));
    }
  }

  @override
  Future<Result<List<Post>>> getFavoritePosts({
    required int userId,
    int limit = 20,
    int page = 1,
  }) async {
    try {
      final favoritePosts = await localDataSource.getFavoritePosts(
        limit: limit,
        page: page,
      );
      return Result.success(favoritePosts.map((p) => p.toEntity()).toList());
    } catch (e) {
      return Result.failure(CacheFailure('Failed to get favorite posts', e.toString()));
    }
  }

  @override
  Future<Result<List<Post>>> searchPosts({
    required String query,
    int limit = 20,
    int page = 1,
  }) async {
    try {
      final posts = await remoteDataSource.searchPosts(
        query: query,
        limit: limit,
        page: page,
      );
      return Result.success(posts.map((p) => p.toEntity()).toList());
    } catch (e) {
      return Result.failure(ServerFailure('Failed to search posts', e.toString()));
    }
  }

  @override
  Future<Result<List<Post>>> refreshPosts({bool clearCache = false}) async {
    try {
      if (clearCache) {
        await localDataSource.clearCache();
      }
      
      final posts = await remoteDataSource.getPosts();
      await localDataSource.cachePosts(posts);
      return Result.success(posts.map((p) => p.toEntity()).toList());
    } catch (e) {
      return Result.failure(ServerFailure('Failed to refresh posts', e.toString()));
    }
  }

  @override
  Future<Result<List<Comment>>> getComments({required int postId}) async {
    try {
      final comments = await remoteDataSource.getComments(postId);
      return Result.success(comments.map((c) => c.toEntity()).toList());
    } catch (e) {
      return Result.failure(ServerFailure('Failed to get comments', e.toString()));
    }
  }
}