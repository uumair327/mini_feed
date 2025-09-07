import 'package:flutter_test/flutter_test.dart';
import 'package:mini_feed/domain/entities/post.dart';

void main() {
  group('Post Entity', () {
    final testPost = Post(
      id: 1,
      title: 'Test Post Title',
      body: 'This is a test post body with some content that is longer than the preview limit to test the bodyPreview functionality properly.',
      userId: 123,
      isFavorite: false,
      isOptimistic: false,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 2),
    );

    test('should create post with required fields', () {
      // Arrange & Act
      const post = Post(
        id: 1,
        title: 'Test Title',
        body: 'Test Body',
        userId: 123,
      );

      // Assert
      expect(post.id, equals(1));
      expect(post.title, equals('Test Title'));
      expect(post.body, equals('Test Body'));
      expect(post.userId, equals(123));
      expect(post.isFavorite, isFalse);
      expect(post.isOptimistic, isFalse);
      expect(post.createdAt, isNull);
      expect(post.updatedAt, isNull);
    });

    test('should return correct body preview for long content', () {
      // Act
      final preview = testPost.bodyPreview;

      // Assert
      expect(preview.length, equals(103)); // 100 chars + '...'
      expect(preview.endsWith('...'), isTrue);
      expect(preview.startsWith('This is a test post body'), isTrue);
    });

    test('should return full body as preview for short content', () {
      // Arrange
      const shortPost = Post(
        id: 1,
        title: 'Short',
        body: 'Short body',
        userId: 123,
      );

      // Act
      final preview = shortPost.bodyPreview;

      // Assert
      expect(preview, equals('Short body'));
      expect(preview.endsWith('...'), isFalse);
    });

    test('should return true for hasContent when title and body exist', () {
      // Act & Assert
      expect(testPost.hasContent, isTrue);
    });

    test('should return false for hasContent when title is empty', () {
      // Arrange
      const post = Post(
        id: 1,
        title: '',
        body: 'Test Body',
        userId: 123,
      );

      // Act & Assert
      expect(post.hasContent, isFalse);
    });

    test('should return false for hasContent when body is empty', () {
      // Arrange
      const post = Post(
        id: 1,
        title: 'Test Title',
        body: '',
        userId: 123,
      );

      // Act & Assert
      expect(post.hasContent, isFalse);
    });

    test('should validate post for creation correctly', () {
      // Arrange
      const validPost = Post(
        id: 1,
        title: 'Valid Title',
        body: 'Valid Body',
        userId: 123,
      );
      const invalidPost1 = Post(
        id: 1,
        title: '   ',
        body: 'Valid Body',
        userId: 123,
      );
      const invalidPost2 = Post(
        id: 1,
        title: 'Valid Title',
        body: '   ',
        userId: 123,
      );

      // Act & Assert
      expect(validPost.isValidForCreation, isTrue);
      expect(invalidPost1.isValidForCreation, isFalse);
      expect(invalidPost2.isValidForCreation, isFalse);
    });

    test('should create copy with updated fields', () {
      // Act
      final updatedPost = testPost.copyWith(
        title: 'Updated Title',
        isFavorite: true,
      );

      // Assert
      expect(updatedPost.id, equals(testPost.id));
      expect(updatedPost.title, equals('Updated Title'));
      expect(updatedPost.body, equals(testPost.body));
      expect(updatedPost.userId, equals(testPost.userId));
      expect(updatedPost.isFavorite, isTrue);
      expect(updatedPost.isOptimistic, equals(testPost.isOptimistic));
    });

    test('should toggle favorite status', () {
      // Act
      final favoritedPost = testPost.toggleFavorite();
      final unfavoritedPost = favoritedPost.toggleFavorite();

      // Assert
      expect(testPost.isFavorite, isFalse);
      expect(favoritedPost.isFavorite, isTrue);
      expect(unfavoritedPost.isFavorite, isFalse);
    });

    test('should mark post as synced', () {
      // Arrange
      final optimisticPost = testPost.copyWith(isOptimistic: true);

      // Act
      final syncedPost = optimisticPost.markAsSynced(syncedId: 999);

      // Assert
      expect(syncedPost.id, equals(999));
      expect(syncedPost.isOptimistic, isFalse);
      expect(syncedPost.updatedAt, isNotNull);
      expect(syncedPost.updatedAt!.isAfter(testPost.updatedAt!), isTrue);
    });

    test('should create optimistic post', () {
      // Act
      final optimisticPost = Post.optimistic(
        title: 'Optimistic Title',
        body: 'Optimistic Body',
        userId: 456,
        tempId: 12345,
      );

      // Assert
      expect(optimisticPost.id, equals(12345));
      expect(optimisticPost.title, equals('Optimistic Title'));
      expect(optimisticPost.body, equals('Optimistic Body'));
      expect(optimisticPost.userId, equals(456));
      expect(optimisticPost.isOptimistic, isTrue);
      expect(optimisticPost.createdAt, isNotNull);
    });

    test('should create optimistic post with generated ID when tempId not provided', () {
      // Act
      final optimisticPost = Post.optimistic(
        title: 'Optimistic Title',
        body: 'Optimistic Body',
        userId: 456,
      );

      // Assert
      expect(optimisticPost.id, isA<int>());
      expect(optimisticPost.isOptimistic, isTrue);
    });

    test('should support equality comparison', () {
      // Arrange
      const post1 = Post(
        id: 1,
        title: 'Title',
        body: 'Body',
        userId: 123,
      );
      const post2 = Post(
        id: 1,
        title: 'Title',
        body: 'Body',
        userId: 123,
      );
      const post3 = Post(
        id: 2,
        title: 'Title',
        body: 'Body',
        userId: 123,
      );

      // Act & Assert
      expect(post1, equals(post2));
      expect(post1, isNot(equals(post3)));
    });

    test('should have proper toString representation', () {
      // Act
      final stringRepresentation = testPost.toString();

      // Assert
      expect(stringRepresentation, contains('Post('));
      expect(stringRepresentation, contains('id: 1'));
      expect(stringRepresentation, contains('title: Test Post Title'));
      expect(stringRepresentation, contains('userId: 123'));
      expect(stringRepresentation, contains('isFavorite: false'));
      expect(stringRepresentation, contains('isOptimistic: false'));
    });
  });
}