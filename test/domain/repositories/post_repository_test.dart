import 'package:flutter_test/flutter_test.dart';
import 'package:mini_feed/core/errors/failures.dart';
import 'package:mini_feed/core/utils/result.dart';
import 'package:mini_feed/domain/entities/comment.dart';
import 'package:mini_feed/domain/entities/post.dart';
import 'package:mini_feed/domain/repositories/post_repository.dart';

// Mock implementation for testing the interface contract
class MockPostRepository implements PostRepository {
  final List<Post> _posts = [
    const Post(
      id: 1,
      title: 'First Post',
      body: 'This is the first post content',
      userId: 1,
    ),
    const Post(
      id: 2,
      title: 'Second Post',
      body: 'This is the second post content',
      userId: 2,
      isFavorite: true,
    ),
  ];

  final List<Comment> _comments = [
    const Comment(
      id: 1,
      postId: 1,
      name: 'John Doe',
      email: 'john@example.com',
      body: 'Great post!',
    ),
    const Comment(
      id: 2,
      postId: 1,
      name: 'Jane Smith',
      email: 'jane@example.com',
      body: 'Thanks for sharing.',
    ),
  ];

  @override
  Future<Result<List<Post>>> getPosts({
    int page = 1,
    int limit = 20,
    bool forceRefresh = false,
  }) async {
    await Future.delayed(const Duration(milliseconds: 50));

    if (page < 1) {
      return Result.failure(const ValidationFailure('Page must be >= 1'));
    }

    // Simulate pagination
    final startIndex = (page - 1) * limit;
    final endIndex = startIndex + limit;
    
    if (startIndex >= _posts.length) {
      return Result.success([]);
    }

    final paginatedPosts = _posts.sublist(
      startIndex,
      endIndex > _posts.length ? _posts.length : endIndex,
    );

    return Result.success(paginatedPosts);
  }

  @override
  Future<Result<Post>> getPost({
    required int postId,
    bool forceRefresh = false,
  }) async {
    await Future.delayed(const Duration(milliseconds: 50));

    try {
      final post = _posts.firstWhere((p) => p.id == postId);
      return Result.success(post);
    } catch (e) {
      return Result.failure(const NotFoundFailure('Post not found'));
    }
  }

  @override
  Future<Result<List<Comment>>> getComments({
    required int postId,
    bool forceRefresh = false,
  }) async {
    await Future.delayed(const Duration(milliseconds: 50));

    final postComments = _comments.where((c) => c.postId == postId).toList();
    return Result.success(postComments);
  }

  @override
  Future<Result<Post>> createPost({
    required String title,
    required String body,
    required int userId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));

    if (title.trim().isEmpty || body.trim().isEmpty) {
      return Result.failure(const ValidationFailure('Title and body are required'));
    }

    final newPost = Post(
      id: _posts.length + 1,
      title: title,
      body: body,
      userId: userId,
      createdAt: DateTime.now(),
    );

    _posts.add(newPost);
    return Result.success(newPost);
  }

  @override
  Future<Result<List<Post>>> searchPosts({
    required String query,
    int page = 1,
    int limit = 20,
  }) async {
    await Future.delayed(const Duration(milliseconds: 100));

    if (query.trim().isEmpty) {
      return Result.failure(const ValidationFailure('Search query cannot be empty'));
    }

    final searchResults = _posts.where((post) =>
        post.title.toLowerCase().contains(query.toLowerCase()) ||
        post.body.toLowerCase().contains(query.toLowerCase())).toList();

    // Apply pagination to search results
    final startIndex = (page - 1) * limit;
    final endIndex = startIndex + limit;
    
    if (startIndex >= searchResults.length) {
      return Result.success([]);
    }

    final paginatedResults = searchResults.sublist(
      startIndex,
      endIndex > searchResults.length ? searchResults.length : endIndex,
    );

    return Result.success(paginatedResults);
  }

  @override
  Future<Result<Post>> toggleFavorite({
    required int postId,
    required bool isFavorite,
  }) async {
    await Future.delayed(const Duration(milliseconds: 50));

    try {
      final postIndex = _posts.indexWhere((p) => p.id == postId);
      if (postIndex == -1) {
        return Result.failure(const NotFoundFailure('Post not found'));
      }

      final updatedPost = _posts[postIndex].copyWith(isFavorite: isFavorite);
      _posts[postIndex] = updatedPost;
      
      return Result.success(updatedPost);
    } catch (e) {
      return Result.failure(const ServerFailure('Failed to update favorite status', 500));
    }
  }

  @override
  Future<Result<List<Post>>> refreshPosts({bool clearCache = false}) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    // Simulate refresh by returning all posts
    return Result.success(List.from(_posts));
  }

  @override
  Future<Result<List<Post>>> getFavoritePosts({
    required int userId,
    int page = 1,
    int limit = 20,
  }) async {
    await Future.delayed(const Duration(milliseconds: 50));

    final favoritePosts = _posts.where((post) => post.isFavorite).toList();
    
    // Apply pagination
    final startIndex = (page - 1) * limit;
    final endIndex = startIndex + limit;
    
    if (startIndex >= favoritePosts.length) {
      return Result.success([]);
    }

    final paginatedFavorites = favoritePosts.sublist(
      startIndex,
      endIndex > favoritePosts.length ? favoritePosts.length : endIndex,
    );

    return Result.success(paginatedFavorites);
  }

  @override
  Future<Result<void>> deletePost({required int postId}) async {
    await Future.delayed(const Duration(milliseconds: 50));

    final postIndex = _posts.indexWhere((p) => p.id == postId);
    if (postIndex == -1) {
      return Result.failure(const NotFoundFailure('Post not found'));
    }

    _posts.removeAt(postIndex);
    return Result.success(null);
  }

  @override
  Future<Result<List<Post>>> getPostsByUser({
    required int userId,
    int page = 1,
    int limit = 20,
  }) async {
    await Future.delayed(const Duration(milliseconds: 50));

    final userPosts = _posts.where((post) => post.userId == userId).toList();
    
    // Apply pagination
    final startIndex = (page - 1) * limit;
    final endIndex = startIndex + limit;
    
    if (startIndex >= userPosts.length) {
      return Result.success([]);
    }

    final paginatedUserPosts = userPosts.sublist(
      startIndex,
      endIndex > userPosts.length ? userPosts.length : endIndex,
    );

    return Result.success(paginatedUserPosts);
  }
}

void main() {
  group('PostRepository Interface Contract', () {
    late PostRepository repository;

    setUp(() {
      repository = MockPostRepository();
    });

    group('getPosts', () {
      test('should return success with posts list', () async {
        // Act
        final result = await repository.getPosts();

        // Assert
        expect(result.isSuccess, isTrue);
        result.fold(
          (failure) => fail('Expected success but got failure: $failure'),
          (posts) {
            expect(posts, isA<List<Post>>());
            expect(posts.length, greaterThan(0));
          },
        );
      });

      test('should support pagination', () async {
        // Act
        final result = await repository.getPosts(page: 1, limit: 1);

        // Assert
        expect(result.isSuccess, isTrue);
        result.fold(
          (failure) => fail('Expected success but got failure: $failure'),
          (posts) {
            expect(posts.length, equals(1));
          },
        );
      });

      test('should return ValidationFailure for invalid page', () async {
        // Act
        final result = await repository.getPosts(page: 0);

        // Assert
        expect(result.isFailure, isTrue);
        result.fold(
          (failure) => expect(failure, isA<ValidationFailure>()),
          (posts) => fail('Expected failure but got success'),
        );
      });
    });

    group('getPost', () {
      test('should return success with post when post exists', () async {
        // Act
        final result = await repository.getPost(postId: 1);

        // Assert
        expect(result.isSuccess, isTrue);
        result.fold(
          (failure) => fail('Expected success but got failure: $failure'),
          (post) {
            expect(post.id, equals(1));
            expect(post.title, isNotEmpty);
          },
        );
      });

      test('should return NotFoundFailure when post does not exist', () async {
        // Act
        final result = await repository.getPost(postId: 999);

        // Assert
        expect(result.isFailure, isTrue);
        result.fold(
          (failure) => expect(failure, isA<NotFoundFailure>()),
          (post) => fail('Expected failure but got success'),
        );
      });
    });

    group('getComments', () {
      test('should return success with comments list', () async {
        // Act
        final result = await repository.getComments(postId: 1);

        // Assert
        expect(result.isSuccess, isTrue);
        result.fold(
          (failure) => fail('Expected success but got failure: $failure'),
          (comments) {
            expect(comments, isA<List<Comment>>());
            expect(comments.every((c) => c.postId == 1), isTrue);
          },
        );
      });

      test('should return empty list for post with no comments', () async {
        // Act
        final result = await repository.getComments(postId: 999);

        // Assert
        expect(result.isSuccess, isTrue);
        result.fold(
          (failure) => fail('Expected success but got failure: $failure'),
          (comments) {
            expect(comments, isEmpty);
          },
        );
      });
    });

    group('createPost', () {
      test('should return success with created post', () async {
        // Act
        final result = await repository.createPost(
          title: 'New Post',
          body: 'New post content',
          userId: 1,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        result.fold(
          (failure) => fail('Expected success but got failure: $failure'),
          (post) {
            expect(post.title, equals('New Post'));
            expect(post.body, equals('New post content'));
            expect(post.userId, equals(1));
          },
        );
      });

      test('should return ValidationFailure for empty title', () async {
        // Act
        final result = await repository.createPost(
          title: '',
          body: 'Valid body',
          userId: 1,
        );

        // Assert
        expect(result.isFailure, isTrue);
        result.fold(
          (failure) => expect(failure, isA<ValidationFailure>()),
          (post) => fail('Expected failure but got success'),
        );
      });

      test('should return ValidationFailure for empty body', () async {
        // Act
        final result = await repository.createPost(
          title: 'Valid title',
          body: '',
          userId: 1,
        );

        // Assert
        expect(result.isFailure, isTrue);
        result.fold(
          (failure) => expect(failure, isA<ValidationFailure>()),
          (post) => fail('Expected failure but got success'),
        );
      });
    });

    group('searchPosts', () {
      test('should return success with matching posts', () async {
        // Act
        final result = await repository.searchPosts(query: 'First');

        // Assert
        expect(result.isSuccess, isTrue);
        result.fold(
          (failure) => fail('Expected success but got failure: $failure'),
          (posts) {
            expect(posts, isA<List<Post>>());
            expect(posts.any((p) => p.title.contains('First')), isTrue);
          },
        );
      });

      test('should return ValidationFailure for empty query', () async {
        // Act
        final result = await repository.searchPosts(query: '');

        // Assert
        expect(result.isFailure, isTrue);
        result.fold(
          (failure) => expect(failure, isA<ValidationFailure>()),
          (posts) => fail('Expected failure but got success'),
        );
      });
    });

    group('toggleFavorite', () {
      test('should return success with updated post', () async {
        // Act
        final result = await repository.toggleFavorite(
          postId: 1,
          isFavorite: true,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        result.fold(
          (failure) => fail('Expected success but got failure: $failure'),
          (post) {
            expect(post.id, equals(1));
            expect(post.isFavorite, isTrue);
          },
        );
      });

      test('should return NotFoundFailure for non-existent post', () async {
        // Act
        final result = await repository.toggleFavorite(
          postId: 999,
          isFavorite: true,
        );

        // Assert
        expect(result.isFailure, isTrue);
        result.fold(
          (failure) => expect(failure, isA<NotFoundFailure>()),
          (post) => fail('Expected failure but got success'),
        );
      });
    });

    group('refreshPosts', () {
      test('should return success with refreshed posts', () async {
        // Act
        final result = await repository.refreshPosts();

        // Assert
        expect(result.isSuccess, isTrue);
        result.fold(
          (failure) => fail('Expected success but got failure: $failure'),
          (posts) {
            expect(posts, isA<List<Post>>());
          },
        );
      });
    });

    group('getFavoritePosts', () {
      test('should return success with favorite posts only', () async {
        // Act
        final result = await repository.getFavoritePosts(userId: 1);

        // Assert
        expect(result.isSuccess, isTrue);
        result.fold(
          (failure) => fail('Expected success but got failure: $failure'),
          (posts) {
            expect(posts, isA<List<Post>>());
            expect(posts.every((p) => p.isFavorite), isTrue);
          },
        );
      });
    });

    group('deletePost', () {
      test('should return success when post is deleted', () async {
        // Act
        final result = await repository.deletePost(postId: 1);

        // Assert
        expect(result.isSuccess, isTrue);
      });

      test('should return NotFoundFailure for non-existent post', () async {
        // Act
        final result = await repository.deletePost(postId: 999);

        // Assert
        expect(result.isFailure, isTrue);
        result.fold(
          (failure) => expect(failure, isA<NotFoundFailure>()),
          (_) => fail('Expected failure but got success'),
        );
      });
    });

    group('getPostsByUser', () {
      test('should return success with user posts', () async {
        // Act
        final result = await repository.getPostsByUser(userId: 1);

        // Assert
        expect(result.isSuccess, isTrue);
        result.fold(
          (failure) => fail('Expected success but got failure: $failure'),
          (posts) {
            expect(posts, isA<List<Post>>());
            expect(posts.every((p) => p.userId == 1), isTrue);
          },
        );
      });
    });
  });
}