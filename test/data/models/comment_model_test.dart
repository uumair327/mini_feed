import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_feed/data/models/comment_model.dart';
import 'package:mini_feed/domain/entities/comment.dart';

void main() {
  group('CommentModel', () {
    late CommentModel commentModel;
    late Map<String, dynamic> jsonMap;
    late Map<String, dynamic> jsonPlaceholderMap;
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2024, 1, 1, 12, 0, 0);
      
      commentModel = CommentModel(
        id: 1,
        postId: 1,
        name: 'Test Commenter',
        email: 'test@example.com',
        body: 'This is a test comment.',
        createdAt: testDate,
        updatedAt: testDate,
      );

      jsonMap = {
        'id': 1,
        'postId': 1,
        'name': 'Test Commenter',
        'email': 'test@example.com',
        'body': 'This is a test comment.',
        'createdAt': testDate.toIso8601String(),
        'updatedAt': testDate.toIso8601String(),
      };

      jsonPlaceholderMap = {
        'id': 1,
        'postId': 1,
        'name': 'Test Commenter',
        'email': 'test@example.com',
        'body': 'This is a test comment.',
      };
    });

    group('fromJson', () {
      test('should create CommentModel from valid JSON', () {
        // Act
        final result = CommentModel.fromJson(jsonMap);

        // Assert
        expect(result.id, equals(1));
        expect(result.postId, equals(1));
        expect(result.name, equals('Test Commenter'));
        expect(result.email, equals('test@example.com'));
        expect(result.body, equals('This is a test comment.'));
        expect(result.createdAt, equals(testDate));
        expect(result.updatedAt, equals(testDate));
      });

      test('should create CommentModel with null optional fields', () {
        // Arrange
        final minimalJson = {
          'id': 1,
          'postId': 1,
          'name': 'Test Commenter',
          'email': 'test@example.com',
          'body': 'This is a test comment.',
        };

        // Act
        final result = CommentModel.fromJson(minimalJson);

        // Assert
        expect(result.id, equals(1));
        expect(result.postId, equals(1));
        expect(result.name, equals('Test Commenter'));
        expect(result.email, equals('test@example.com'));
        expect(result.body, equals('This is a test comment.'));
        expect(result.createdAt, isNull);
        expect(result.updatedAt, isNull);
      });
    });

    group('toJson', () {
      test('should convert CommentModel to JSON', () {
        // Act
        final result = commentModel.toJson();

        // Assert
        expect(result['id'], equals(1));
        expect(result['postId'], equals(1));
        expect(result['name'], equals('Test Commenter'));
        expect(result['email'], equals('test@example.com'));
        expect(result['body'], equals('This is a test comment.'));
        expect(result['createdAt'], equals(testDate.toIso8601String()));
        expect(result['updatedAt'], equals(testDate.toIso8601String()));
      });

      test('should exclude null date fields from JSON', () {
        // Arrange
        final commentWithoutDates = const CommentModel(
          id: 1,
          postId: 1,
          name: 'Test Commenter',
          email: 'test@example.com',
          body: 'This is a test comment.',
        );

        // Act
        final result = commentWithoutDates.toJson();

        // Assert
        expect(result.containsKey('createdAt'), isFalse);
        expect(result.containsKey('updatedAt'), isFalse);
      });
    });

    group('JSON string conversion', () {
      test('should convert to and from JSON string', () {
        // Act
        final jsonString = commentModel.toJsonString();
        final result = CommentModel.fromJsonString(jsonString);

        // Assert
        expect(result.id, equals(commentModel.id));
        expect(result.postId, equals(commentModel.postId));
        expect(result.name, equals(commentModel.name));
        expect(result.email, equals(commentModel.email));
        expect(result.body, equals(commentModel.body));
        expect(result.createdAt, equals(commentModel.createdAt));
        expect(result.updatedAt, equals(commentModel.updatedAt));
      });
    });

    group('fromDomain and toDomain', () {
      test('should convert from domain entity', () {
        // Arrange
        final domainComment = Comment(
          id: 2,
          postId: 2,
          name: 'Domain Commenter',
          email: 'domain@example.com',
          body: 'Domain comment body.',
          createdAt: testDate,
        );

        // Act
        final result = CommentModel.fromDomain(domainComment);

        // Assert
        expect(result.id, equals(domainComment.id));
        expect(result.postId, equals(domainComment.postId));
        expect(result.name, equals(domainComment.name));
        expect(result.email, equals(domainComment.email));
        expect(result.body, equals(domainComment.body));
        expect(result.createdAt, equals(domainComment.createdAt));
      });

      test('should convert to domain entity', () {
        // Act
        final result = commentModel.toDomain();

        // Assert
        expect(result, isA<Comment>());
        expect(result.id, equals(commentModel.id));
        expect(result.postId, equals(commentModel.postId));
        expect(result.name, equals(commentModel.name));
        expect(result.email, equals(commentModel.email));
        expect(result.body, equals(commentModel.body));
        expect(result.createdAt, equals(commentModel.createdAt));
        expect(result.updatedAt, equals(commentModel.updatedAt));
      });
    });

    group('JSONPlaceholder API format', () {
      test('should create CommentModel from JSONPlaceholder JSON', () {
        // Act
        final result = CommentModel.fromJsonPlaceholder(jsonPlaceholderMap);

        // Assert
        expect(result.id, equals(1));
        expect(result.postId, equals(1));
        expect(result.name, equals('Test Commenter'));
        expect(result.email, equals('test@example.com'));
        expect(result.body, equals('This is a test comment.'));
        expect(result.createdAt, isNull);
        expect(result.updatedAt, isNull);
      });

      test('should convert to JSONPlaceholder JSON format', () {
        // Act
        final result = commentModel.toJsonPlaceholder();

        // Assert
        expect(result['id'], equals(1));
        expect(result['postId'], equals(1));
        expect(result['name'], equals('Test Commenter'));
        expect(result['email'], equals('test@example.com'));
        expect(result['body'], equals('This is a test comment.'));
        expect(result.containsKey('createdAt'), isFalse);
        expect(result.containsKey('updatedAt'), isFalse);
      });
    });

    group('local storage format', () {
      test('should convert to local storage JSON format', () {
        // Act
        final result = commentModel.toLocalStorageJson();

        // Assert
        expect(result['id'], equals(1));
        expect(result['postId'], equals(1));
        expect(result['name'], equals('Test Commenter'));
        expect(result['email'], equals('test@example.com'));
        expect(result['body'], equals('This is a test comment.'));
        expect(result['createdAt'], equals(testDate.millisecondsSinceEpoch));
        expect(result['updatedAt'], equals(testDate.millisecondsSinceEpoch));
      });

      test('should create CommentModel from local storage JSON', () {
        // Arrange
        final localStorageJson = {
          'id': 1,
          'postId': 1,
          'name': 'Test Commenter',
          'email': 'test@example.com',
          'body': 'This is a test comment.',
          'createdAt': testDate.millisecondsSinceEpoch,
          'updatedAt': testDate.millisecondsSinceEpoch,
        };

        // Act
        final result = CommentModel.fromLocalStorageJson(localStorageJson);

        // Assert
        expect(result.id, equals(1));
        expect(result.postId, equals(1));
        expect(result.name, equals('Test Commenter'));
        expect(result.email, equals('test@example.com'));
        expect(result.body, equals('This is a test comment.'));
        expect(result.createdAt, equals(testDate));
        expect(result.updatedAt, equals(testDate));
      });

      test('should handle null dates in local storage format', () {
        // Arrange
        final localStorageJson = {
          'id': 1,
          'postId': 1,
          'name': 'Test Commenter',
          'email': 'test@example.com',
          'body': 'This is a test comment.',
          'createdAt': null,
          'updatedAt': null,
        };

        // Act
        final result = CommentModel.fromLocalStorageJson(localStorageJson);

        // Assert
        expect(result.createdAt, isNull);
        expect(result.updatedAt, isNull);
      });
    });

    group('copyWith', () {
      test('should create copy with updated fields', () {
        // Act
        final result = commentModel.copyWith(
          name: 'Updated Commenter',
          body: 'Updated comment body.',
        );

        // Assert
        expect(result.id, equals(commentModel.id));
        expect(result.postId, equals(commentModel.postId));
        expect(result.name, equals('Updated Commenter'));
        expect(result.email, equals(commentModel.email));
        expect(result.body, equals('Updated comment body.'));
        expect(result.createdAt, equals(commentModel.createdAt));
        expect(result.updatedAt, equals(commentModel.updatedAt));
      });

      test('should keep original values when no updates provided', () {
        // Act
        final result = commentModel.copyWith();

        // Assert
        expect(result.id, equals(commentModel.id));
        expect(result.postId, equals(commentModel.postId));
        expect(result.name, equals(commentModel.name));
        expect(result.email, equals(commentModel.email));
        expect(result.body, equals(commentModel.body));
        expect(result.createdAt, equals(commentModel.createdAt));
        expect(result.updatedAt, equals(commentModel.updatedAt));
      });
    });

    group('forPost factory', () {
      test('should create comment for specific post', () {
        // Act
        final result = CommentModel.forPost(
          id: 99,
          postId: 5,
          name: 'Post Commenter',
          email: 'post@example.com',
          body: 'Comment for post.',
        );

        // Assert
        expect(result.id, equals(99));
        expect(result.postId, equals(5));
        expect(result.name, equals('Post Commenter'));
        expect(result.email, equals('post@example.com'));
        expect(result.body, equals('Comment for post.'));
        expect(result.createdAt, isNotNull);
      });
    });

    group('mock factory', () {
      test('should create mock comment with default values', () {
        // Act
        final result = CommentModel.mock();

        // Assert
        expect(result.id, equals(1));
        expect(result.postId, equals(1));
        expect(result.name, equals('Test Commenter'));
        expect(result.email, equals('test@example.com'));
        expect(result.body, equals('This is a test comment.'));
        expect(result.createdAt, isNotNull);
      });

      test('should create mock comment with custom values', () {
        // Act
        final result = CommentModel.mock(
          id: 99,
          postId: 5,
          name: 'Custom Commenter',
        );

        // Assert
        expect(result.id, equals(99));
        expect(result.postId, equals(5));
        expect(result.name, equals('Custom Commenter'));
      });
    });

    group('toCreateRequestJson', () {
      test('should create JSON for API request', () {
        // Act
        final result = commentModel.toCreateRequestJson();

        // Assert
        expect(result['postId'], equals(1));
        expect(result['name'], equals('Test Commenter'));
        expect(result['email'], equals('test@example.com'));
        expect(result['body'], equals('This is a test comment.'));
        expect(result.containsKey('id'), isFalse);
        expect(result.containsKey('createdAt'), isFalse);
        expect(result.containsKey('updatedAt'), isFalse);
      });
    });

    group('isValidForCreation', () {
      test('should return true for valid comment', () {
        // Act
        final isValid = commentModel.isValidForCreation;

        // Assert
        expect(isValid, isTrue);
      });

      test('should return false for comment with empty name', () {
        // Arrange
        final invalidComment = commentModel.copyWith(name: '');

        // Act
        final isValid = invalidComment.isValidForCreation;

        // Assert
        expect(isValid, isFalse);
      });

      test('should return false for comment with empty email', () {
        // Arrange
        final invalidComment = commentModel.copyWith(email: '');

        // Act
        final isValid = invalidComment.isValidForCreation;

        // Assert
        expect(isValid, isFalse);
      });

      test('should return false for comment with empty body', () {
        // Arrange
        final invalidComment = commentModel.copyWith(body: '');

        // Act
        final isValid = invalidComment.isValidForCreation;

        // Assert
        expect(isValid, isFalse);
      });

      test('should return false for comment with invalid email', () {
        // Arrange
        final invalidComment = commentModel.copyWith(email: 'invalid-email');

        // Act
        final isValid = invalidComment.isValidForCreation;

        // Assert
        expect(isValid, isFalse);
      });
    });

    group('inherited properties', () {
      test('should inherit bodyPreview property from Comment entity', () {
        // Act
        final bodyPreview = commentModel.bodyPreview;

        // Assert
        expect(bodyPreview, equals('This is a test comment.'));
      });

      test('should inherit hasValidContent property from Comment entity', () {
        // Act
        final hasValidContent = commentModel.hasValidContent;

        // Assert
        expect(hasValidContent, isTrue);
      });

      test('should inherit commenterInitials property from Comment entity', () {
        // Act
        final initials = commentModel.commenterInitials;

        // Assert
        expect(initials, equals('TC'));
      });

      test('should inherit commenterInfo property from Comment entity', () {
        // Act
        final info = commentModel.commenterInfo;

        // Assert
        expect(info, equals('Test Commenter (test@example.com)'));
      });
    });

    group('toString', () {
      test('should return meaningful string representation', () {
        // Act
        final result = commentModel.toString();

        // Assert
        expect(result, contains('CommentModel'));
        expect(result, contains('Test Commenter'));
        expect(result, contains('test@example.com'));
      });
    });
  });
}