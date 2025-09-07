import 'package:flutter_test/flutter_test.dart';
import 'package:mini_feed/core/errors/failures.dart';
import 'package:mini_feed/core/utils/result.dart';
import 'package:mini_feed/domain/entities/comment.dart';
import 'package:mini_feed/domain/repositories/comment_repository.dart';

// Mock implementation for testing
class MockCommentRepository implements CommentRepository {
  final List<Comment> _comments = [
    const Comment(
      id: 1,
      postId: 1,
      name: 'John Doe',
      email: 'john@example.com',
      body: 'This is a test comment',
    ),
    const Comment(
      id: 2,
      postId: 1,
      name: 'Jane Smith',
      email: 'jane@example.com',
      body: 'Another test comment',
    ),
    const Comment(
      id: 3,
      postId: 2,
      name: 'Bob Johnson',
      email: 'bob@example.com',
      body: 'Comment on post 2',
    ),
  ];
  
  int _nextId = 4;

  @override
  Future<Result<List<Comment>>> getComments({
    required int postId,
    int? page,
    int? limit,
    bool forceRefresh = false,
  }) async {
    final postComments = _comments.where((c) => c.postId == postId).toList();
    
    final startIndex = ((page ?? 1) - 1) * (limit ?? 10);
    final endIndex = startIndex + (limit ?? 10);
    
    if (startIndex >= postComments.length) {
      return success([]);
    }
    
    final paginatedComments = postComments.sublist(
      startIndex,
      endIndex > postComments.length ? postComments.length : endIndex,
    );
    
    return success(paginatedComments);
  }

  @override
  Future<Result<Comment>> getComment({
    required int id,
    bool forceRefresh = false,
  }) async {
    try {
      final comment = _comments.firstWhere((c) => c.id == id);
      return success(comment);
    } catch (e) {
      return failure(const NotFoundFailure('Comment not found'));
    }
  }

  @override
  Future<Result<Comment>> createComment({
    required int postId,
    required String name,
    required String email,
    required String body,
  }) async {
    if (name.isEmpty || email.isEmpty || body.isEmpty || !email.contains('@')) {
      return failure(const ValidationFailure('Invalid comment data'));
    }
    
    final newComment = Comment(
      id: _nextId++,
      postId: postId,
      name: name,
      email: email,
      body: body,
    );
    
    _comments.add(newComment);
    return success(newComment);
  }

  @override
  Future<Result<Comment>> updateComment({
    required int id,
    String? name,
    String? email,
    String? body,
  }) async {
    try {
      final index = _comments.indexWhere((c) => c.id == id);
      if (index == -1) {
        return failure(const NotFoundFailure('Comment not found'));
      }
      
      final updatedComment = _comments[index].copyWith(
        name: name ?? _comments[index].name,
        email: email ?? _comments[index].email,
        body: body ?? _comments[index].body,
      );
      
      _comments[index] = updatedComment;
      return success(updatedComment);
    } catch (e) {
      return failure(const ServerFailure('Update failed', 500));
    }
  }

  @override
  Future<Result<void>> deleteComment({required int id}) async {
    final index = _comments.indexWhere((c) => c.id == id);
    if (index == -1) {
      return failure(const NotFoundFailure('Comment not found'));
    }
    
    _comments.removeAt(index);
    return success(null);
  }

  @override
  Future<Result<List<Comment>>> getCommentsByUser({
    required String email,
    int? page,
    int? limit,
    bool forceRefresh = false,
  }) async {
    final userComments = _comments.where((c) => c.email == email).toList();
    return success(userComments);
  }

  @override
  Future<Result<List<Comment>>> searchComments({
    required String query,
    int? postId,
    int? page,
    int? limit,
  }) async {
    var searchResults = _comments.where((c) => 
        c.body.toLowerCase().contains(query.toLowerCase()) ||
        c.name.toLowerCase().contains(query.toLowerCase()));
    
    if (postId != null) {
      searchResults = searchResults.where((c) => c.postId == postId);
    }
    
    return success(searchResults.toList());
  }

  @override
  Future<Result<List<Comment>>> getCachedComments({
    required int postId,
  }) async {
    final cachedComments = _comments.where((c) => c.postId == postId).toList();
    return success(cachedComments);
  }

  @override
  Future<Result<int>> getCommentsCount({
    required int postId,
  }) async {
    final count = _comments.where((c) => c.postId == postId).length;
    return success(count);
  }

  @override
  Future<bool> hasMoreComments({required int postId}) async {
    return false; // Mock: no more comments
  }

  @override
  Future<Result<List<Comment>>> refreshComments({
    required int postId,
  }) async {
    final postComments = _comments.where((c) => c.postId == postId).toList();
    return success(postComments);
  }

  @override
  Future<Result<void>> clearCacheForPost({
    required int postId,
  }) async {
    return success(null);
  }

  @override
  Future<Result<void>> clearAllCache() async {
    return success(null);
  }

  @override
  Future<Result<void>> reportComment({
    required int id,
    required String reason,
  }) async {
    if (reason.isEmpty) {
      return failure(const ValidationFailure('Reason required'));
    }
    return success(null);
  }

  @override
  Future<Result<List<Comment>>> getRecentComments({
    int? limit,
    bool forceRefresh = false,
  }) async {
    final recentComments = _comments.take(limit ?? 10).toList();
    return success(recentComments);
  }
}

void main() {
  group('CommentRepository Interface', () {
    late MockCommentRepository repository;

    setUp(() {
      repository = MockCommentRepository();
    });

    test('should implement all required methods', () {
      // Verify that MockCommentRepository implements CommentRepository
      expect(repository, isA<CommentRepository>());
    });

    test('should get comments for a post', () async {
      // Act
      final result = await repository.getComments(postId: 1);

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.successValue, isA<List<Comment>>());
      expect(result.successValue!.every((c) => c.postId == 1), isTrue);
    });

    test('should get specific comment by ID', () async {
      // Act
      final result = await repository.getComment(id: 1);

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.successValue?.id, equals(1));
      expect(result.successValue?.name, equals('John Doe'));
    });

    test('should fail to get non-existent comment', () async {
      // Act
      final result = await repository.getComment(id: 999);

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.failureValue, isA<NotFoundFailure>());
    });

    test('should create new comment successfully', () async {
      // Act
      final result = await repository.createComment(
        postId: 1,
        name: 'New Commenter',
        email: 'new@example.com',
        body: 'New comment content',
      );

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.successValue?.name, equals('New Commenter'));
      expect(result.successValue?.email, equals('new@example.com'));
      expect(result.successValue?.body, equals('New comment content'));
    });

    test('should fail to create comment with invalid email', () async {
      // Act
      final result = await repository.createComment(
        postId: 1,
        name: 'Test User',
        email: 'invalid-email',
        body: 'Comment content',
      );

      // Assert
      expect(result.isFailure, isTrue);
      expect(result.failureValue, isA<ValidationFailure>());
    });

    test('should update comment successfully', () async {
      // Act
      final result = await repository.updateComment(
        id: 1,
        body: 'Updated comment content',
      );

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.successValue?.body, equals('Updated comment content'));
    });

    test('should delete comment successfully', () async {
      // Act
      final result = await repository.deleteComment(id: 1);

      // Assert
      expect(result.isSuccess, isTrue);
    });

    test('should get comments by user email', () async {
      // Act
      final result = await repository.getCommentsByUser(
        email: 'john@example.com',
      );

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.successValue!.every((c) => c.email == 'john@example.com'), isTrue);
    });

    test('should search comments by query', () async {
      // Act
      final result = await repository.searchComments(
        query: 'test comment',
      );

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.successValue!.isNotEmpty, isTrue);
    });

    test('should get cached comments for post', () async {
      // Act
      final result = await repository.getCachedComments(postId: 1);

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.successValue!.every((c) => c.postId == 1), isTrue);
    });

    test('should get comments count for post', () async {
      // Act
      final result = await repository.getCommentsCount(postId: 1);

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.successValue, isA<int>());
      expect(result.successValue! >= 0, isTrue);
    });

    test('should check if has more comments', () async {
      // Act
      final hasMore = await repository.hasMoreComments(postId: 1);

      // Assert
      expect(hasMore, isA<bool>());
    });

    test('should refresh comments for post', () async {
      // Act
      final result = await repository.refreshComments(postId: 1);

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.successValue!.every((c) => c.postId == 1), isTrue);
    });

    test('should report comment successfully', () async {
      // Act
      final result = await repository.reportComment(
        id: 1,
        reason: 'Inappropriate content',
      );

      // Assert
      expect(result.isSuccess, isTrue);
    });

    test('should get recent comments', () async {
      // Act
      final result = await repository.getRecentComments(limit: 5);

      // Assert
      expect(result.isSuccess, isTrue);
      expect(result.successValue, isA<List<Comment>>());
      expect(result.successValue!.length <= 5, isTrue);
    });
  });
}