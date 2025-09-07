import 'package:flutter_test/flutter_test.dart';
import 'package:mini_feed/domain/entities/comment.dart';

void main() {
  group('Comment Entity', () {
    final testComment = Comment(
      id: 1,
      postId: 123,
      name: 'John Doe',
      email: 'john.doe@example.com',
      body: 'This is a test comment with some content that is longer than the preview limit to test the bodyPreview functionality.',
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 2),
    );

    test('should create comment with required fields', () {
      // Arrange & Act
      const comment = Comment(
        id: 1,
        postId: 123,
        name: 'John Doe',
        email: 'john@example.com',
        body: 'Test comment body',
      );

      // Assert
      expect(comment.id, equals(1));
      expect(comment.postId, equals(123));
      expect(comment.name, equals('John Doe'));
      expect(comment.email, equals('john@example.com'));
      expect(comment.body, equals('Test comment body'));
      expect(comment.createdAt, isNull);
      expect(comment.updatedAt, isNull);
    });

    test('should return correct body preview for long content', () {
      // Act
      final preview = testComment.bodyPreview;

      // Assert
      expect(preview.length, equals(83)); // 80 chars + '...'
      expect(preview.endsWith('...'), isTrue);
      expect(preview.startsWith('This is a test comment'), isTrue);
    });

    test('should return full body as preview for short content', () {
      // Arrange
      const shortComment = Comment(
        id: 1,
        postId: 123,
        name: 'John',
        email: 'john@example.com',
        body: 'Short comment',
      );

      // Act
      final preview = shortComment.bodyPreview;

      // Assert
      expect(preview, equals('Short comment'));
      expect(preview.endsWith('...'), isFalse);
    });

    test('should validate comment content correctly', () {
      // Arrange
      const validComment = Comment(
        id: 1,
        postId: 123,
        name: 'John Doe',
        email: 'john@example.com',
        body: 'Valid comment',
      );
      const invalidComment1 = Comment(
        id: 1,
        postId: 123,
        name: '',
        email: 'john@example.com',
        body: 'Valid comment',
      );
      const invalidComment2 = Comment(
        id: 1,
        postId: 123,
        name: 'John Doe',
        email: 'invalid-email',
        body: 'Valid comment',
      );
      const invalidComment3 = Comment(
        id: 1,
        postId: 123,
        name: 'John Doe',
        email: 'john@example.com',
        body: '',
      );

      // Act & Assert
      expect(validComment.hasValidContent, isTrue);
      expect(invalidComment1.hasValidContent, isFalse);
      expect(invalidComment2.hasValidContent, isFalse);
      expect(invalidComment3.hasValidContent, isFalse);
    });

    test('should return correct commenter initials for full name', () {
      // Act
      final initials = testComment.commenterInitials;

      // Assert
      expect(initials, equals('JD'));
    });

    test('should return correct commenter initials for single name', () {
      // Arrange
      const comment = Comment(
        id: 1,
        postId: 123,
        name: 'John',
        email: 'john@example.com',
        body: 'Test comment',
      );

      // Act
      final initials = comment.commenterInitials;

      // Assert
      expect(initials, equals('J'));
    });

    test('should return question mark for empty name', () {
      // Arrange
      const comment = Comment(
        id: 1,
        postId: 123,
        name: '',
        email: 'john@example.com',
        body: 'Test comment',
      );

      // Act
      final initials = comment.commenterInitials;

      // Assert
      expect(initials, equals('?'));
    });

    test('should return correct commenter initials for multiple names', () {
      // Arrange
      const comment = Comment(
        id: 1,
        postId: 123,
        name: 'John Michael Doe',
        email: 'john@example.com',
        body: 'Test comment',
      );

      // Act
      final initials = comment.commenterInitials;

      // Assert
      expect(initials, equals('JD'));
    });

    test('should return correct commenter info', () {
      // Act
      final info = testComment.commenterInfo;

      // Assert
      expect(info, equals('John Doe (john.doe@example.com)'));
    });

    test('should create copy with updated fields', () {
      // Act
      final updatedComment = testComment.copyWith(
        name: 'Jane Doe',
        body: 'Updated comment body',
      );

      // Assert
      expect(updatedComment.id, equals(testComment.id));
      expect(updatedComment.postId, equals(testComment.postId));
      expect(updatedComment.name, equals('Jane Doe'));
      expect(updatedComment.email, equals(testComment.email));
      expect(updatedComment.body, equals('Updated comment body'));
    });

    test('should create comment for post', () {
      // Act
      final comment = Comment.forPost(
        id: 999,
        postId: 456,
        name: 'Test User',
        email: 'test@example.com',
        body: 'Test comment for post',
      );

      // Assert
      expect(comment.id, equals(999));
      expect(comment.postId, equals(456));
      expect(comment.name, equals('Test User'));
      expect(comment.email, equals('test@example.com'));
      expect(comment.body, equals('Test comment for post'));
      expect(comment.createdAt, isNotNull);
    });

    test('should support equality comparison', () {
      // Arrange
      const comment1 = Comment(
        id: 1,
        postId: 123,
        name: 'John',
        email: 'john@example.com',
        body: 'Comment',
      );
      const comment2 = Comment(
        id: 1,
        postId: 123,
        name: 'John',
        email: 'john@example.com',
        body: 'Comment',
      );
      const comment3 = Comment(
        id: 2,
        postId: 123,
        name: 'John',
        email: 'john@example.com',
        body: 'Comment',
      );

      // Act & Assert
      expect(comment1, equals(comment2));
      expect(comment1, isNot(equals(comment3)));
    });

    test('should have proper toString representation', () {
      // Act
      final stringRepresentation = testComment.toString();

      // Assert
      expect(stringRepresentation, contains('Comment('));
      expect(stringRepresentation, contains('id: 1'));
      expect(stringRepresentation, contains('postId: 123'));
      expect(stringRepresentation, contains('name: John Doe'));
      expect(stringRepresentation, contains('email: john.doe@example.com'));
    });
  });
}