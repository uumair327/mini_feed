import 'package:flutter_test/flutter_test.dart';
import 'package:mini_feed/data/models/cached_comment.dart';
import 'package:mini_feed/data/models/comment_model.dart';
import 'package:mini_feed/domain/entities/comment.dart';

void main() {
  group('CachedComment', () {
    late CachedComment cachedComment;
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2024, 1, 1, 12, 0, 0);
      
      cachedComment = CachedComment(
        id: 1,
        postId: 1,
        name: 'Test Commenter',
        email: 'test@example.com',
        body: 'This is a test comment.',
        createdAt: testDate,
        updatedAt: testDate,
        cachedAt: testDate,
        needsSync: false,
        syncAttempts: 0,
      );
    });

    group('constructor', () {
      test('should create CachedComment with all fields', () {
        // Assert
        expect(cachedComment.id, equals(1));
        expect(cachedComment.postId, equals(1));
        expect(cachedComment.name, equals('Test Commenter'));
        expect(cachedComment.email, equals('test@example.com'));
        expect(cachedComment.body, equals('This is a test comment.'));
        expect(cachedComment.createdAt, equals(testDate));
        expect(cachedComment.updatedAt, equals(testDate));
        expect(cachedComment.cachedAt, equals(testDate));
        expect(cachedComment.needsSync, isFalse);
        expect(cachedComment.syncAttempts, equals(0));
      });

      test('should set default cachedAt when not provided', () {
        // Arrange
        final now = DateTime.now();
        
        // Act
        final result = CachedComment(
          id: 1,
          postId: 1,
          name: 'Test Commenter',
          email: 'test@example.com',
          body: 'Test comment body',
        );

        // Assert
        expect(result.cachedAt.difference(now).inSeconds, lessThan(1));
      });

      test('should set default values for optional fields', () {
        // Act
        final result = CachedComment(
          id: 1,
          postId: 1,
          name: 'Test Commenter',
          email: 'test@example.com',
          body: 'Test comment body',
        );

        // Assert
        expect(result.needsSync, isFalse);
        expect(result.syncAttempts, equals(0));
        expect(result.syncError, isNull);
      });
    });

    group('toDomain', () {
      test('should convert to domain Comment entity', () {
        // Act
        final result = cachedComment.toDomain();

        // Assert
        expect(result, isA<Comment>());
        expect(result.id, equals(cachedComment.id));
        expect(result.postId, equals(cachedComment.postId));
        expect(result.name, equals(cachedComment.name));
        expect(result.email, equals(cachedComment.email));
        expect(result.body, equals(cachedComment.body));
        expect(result.createdAt, equals(cachedComment.createdAt));
        expect(result.updatedAt, equals(cachedComment.updatedAt));
      });
    });

    group('toModel', () {
      test('should convert to CommentModel', () {
        // Act
        final result = cachedComment.toModel();

        // Assert
        expect(result, isA<CommentModel>());
        expect(result.id, equals(cachedComment.id));
        expect(result.postId, equals(cachedComment.postId));
        expect(result.name, equals(cachedComment.name));
        expect(result.email, equals(cachedComment.email));
        expect(result.body, equals(cachedComment.body));
        expect(result.createdAt, equals(cachedComment.createdAt));
        expect(result.updatedAt, equals(cachedComment.updatedAt));
      });
    });

    group('fromDomain', () {
      test('should create CachedComment from domain Comment entity', () {
        // Arrange
        const domainComment = Comment(
          id: 2,
          postId: 2,
          name: 'Domain Commenter',
          email: 'domain@example.com',
          body: 'Domain comment body.',
        );

        // Act
        final result = CachedComment.fromDomain(domainComment);

        // Assert
        expect(result.id, equals(domainComment.id));
        expect(result.postId, equals(domainComment.postId));
        expect(result.name, equals(domainComment.name));
        expect(result.email, equals(domainComment.email));
        expect(result.body, equals(domainComment.body));
        expect(result.createdAt, equals(domainComment.createdAt));
        expect(result.updatedAt, equals(domainComment.updatedAt));
        expect(result.needsSync, isFalse);
        expect(result.syncAttempts, equals(0));
      });

      test('should create CachedComment with sync metadata', () {
        // Arrange
        const domainComment = Comment(
          id: 2,
          postId: 2,
          name: 'Domain Commenter',
          email: 'domain@example.com',
          body: 'Domain comment body.',
        );

        // Act
        final result = CachedComment.fromDomain(
          domainComment,
          needsSync: true,
          syncError: 'Network error',
          syncAttempts: 2,
        );

        // Assert
        expect(result.needsSync, isTrue);
        expect(result.syncError, equals('Network error'));
        expect(result.syncAttempts, equals(2));
      });
    });

    group('fromModel', () {
      test('should create CachedComment from CommentModel', () {
        // Arrange
        final commentModel = CommentModel(
          id: 3,
          postId: 3,
          name: 'Model Commenter',
          email: 'model@example.com',
          body: 'Model comment body.',
          createdAt: testDate,
        );

        // Act
        final result = CachedComment.fromModel(commentModel);

        // Assert
        expect(result.id, equals(commentModel.id));
        expect(result.postId, equals(commentModel.postId));
        expect(result.name, equals(commentModel.name));
        expect(result.email, equals(commentModel.email));
        expect(result.body, equals(commentModel.body));
        expect(result.createdAt, equals(commentModel.createdAt));
      });
    });

    group('cache expiration', () {
      test('should detect expired cache', () {
        // Arrange
        final oldCachedComment = cachedComment.copyWith(
          cachedAt: DateTime.now().subtract(const Duration(hours: 2)),
        );

        // Act
        final isExpired = oldCachedComment.isExpired(const Duration(hours: 1));

        // Assert
        expect(isExpired, isTrue);
      });

      test('should detect non-expired cache', () {
        // Arrange
        final recentCachedComment = cachedComment.copyWith(
          cachedAt: DateTime.now().subtract(const Duration(minutes: 30)),
        );

        // Act
        final isExpired = recentCachedComment.isExpired(const Duration(hours: 1));

        // Assert
        expect(isExpired, isFalse);
      });

      test('should detect stale cache', () {
        // Arrange
        final staleCachedComment = cachedComment.copyWith(
          cachedAt: DateTime.now().subtract(const Duration(minutes: 45)),
        );

        // Act
        final isStale = staleCachedComment.isStale(const Duration(minutes: 30));

        // Assert
        expect(isStale, isTrue);
      });
    });

    group('copyWith', () {
      test('should create copy with updated fields', () {
        // Act
        final result = cachedComment.copyWith(
          name: 'Updated Commenter',
          needsSync: true,
          syncAttempts: 3,
        );

        // Assert
        expect(result.id, equals(cachedComment.id));
        expect(result.postId, equals(cachedComment.postId));
        expect(result.name, equals('Updated Commenter'));
        expect(result.email, equals(cachedComment.email));
        expect(result.body, equals(cachedComment.body));
        expect(result.needsSync, isTrue);
        expect(result.syncAttempts, equals(3));
      });

      test('should keep original values when no updates provided', () {
        // Act
        final result = cachedComment.copyWith();

        // Assert
        expect(result.id, equals(cachedComment.id));
        expect(result.postId, equals(cachedComment.postId));
        expect(result.name, equals(cachedComment.name));
        expect(result.email, equals(cachedComment.email));
        expect(result.body, equals(cachedComment.body));
        expect(result.needsSync, equals(cachedComment.needsSync));
        expect(result.syncAttempts, equals(cachedComment.syncAttempts));
      });
    });

    group('sync operations', () {
      test('should mark for sync', () {
        // Act
        final result = cachedComment.markForSync(error: 'Network error');

        // Assert
        expect(result.needsSync, isTrue);
        expect(result.syncError, equals('Network error'));
        expect(result.syncAttempts, equals(1));
      });

      test('should mark for sync without error', () {
        // Act
        final result = cachedComment.markForSync();

        // Assert
        expect(result.needsSync, isTrue);
        expect(result.syncError, isNull);
        expect(result.syncAttempts, equals(0));
      });

      test('should mark as synced', () {
        // Arrange
        final unsyncedComment = cachedComment.copyWith(
          needsSync: true,
          syncError: 'Error',
          syncAttempts: 2,
        );

        // Act
        final result = unsyncedComment.markAsSynced();

        // Assert
        expect(result.needsSync, isFalse);
        expect(result.syncError, isNull);
        expect(result.syncAttempts, equals(0));
        expect(result.cachedAt.isAfter(unsyncedComment.cachedAt), isTrue);
      });

      test('should determine if sync should be retried', () {
        // Arrange
        final failedComment = cachedComment.copyWith(
          needsSync: true,
          syncAttempts: 2,
        );

        // Act & Assert
        expect(failedComment.shouldRetrySync(maxAttempts: 3), isTrue);
        expect(failedComment.shouldRetrySync(maxAttempts: 2), isFalse);
      });

      test('should not retry sync when not needed', () {
        // Arrange
        final syncedComment = cachedComment.copyWith(needsSync: false);

        // Act & Assert
        expect(syncedComment.shouldRetrySync(), isFalse);
      });
    });

    group('cache operations', () {
      test('should refresh cache timestamp', () {
        // Act
        final result = cachedComment.refreshCache();

        // Assert
        expect(result.cachedAt.isAfter(cachedComment.cachedAt), isTrue);
      });
    });

    group('cache age', () {
      test('should calculate cache age in minutes', () {
        // Arrange
        final oldComment = cachedComment.copyWith(
          cachedAt: DateTime.now().subtract(const Duration(minutes: 30)),
        );

        // Act
        final ageInMinutes = oldComment.cacheAgeInMinutes;

        // Assert
        expect(ageInMinutes, greaterThanOrEqualTo(29));
        expect(ageInMinutes, lessThanOrEqualTo(31));
      });

      test('should calculate cache age in hours', () {
        // Arrange
        final oldComment = cachedComment.copyWith(
          cachedAt: DateTime.now().subtract(const Duration(hours: 2)),
        );

        // Act
        final ageInHours = oldComment.cacheAgeInHours;

        // Assert
        expect(ageInHours, equals(2));
      });
    });

    group('equality and hashCode', () {
      test('should be equal when all properties are the same', () {
        // Arrange
        final other = CachedComment(
          id: 1,
          postId: 1,
          name: 'Test Commenter',
          email: 'test@example.com',
          body: 'This is a test comment.',
          createdAt: testDate,
          updatedAt: testDate,
          cachedAt: testDate,
          needsSync: false,
          syncAttempts: 0,
        );

        // Assert
        expect(cachedComment, equals(other));
        expect(cachedComment.hashCode, equals(other.hashCode));
      });

      test('should not be equal when properties differ', () {
        // Arrange
        final other = cachedComment.copyWith(name: 'Different Commenter');

        // Assert
        expect(cachedComment, isNot(equals(other)));
        expect(cachedComment.hashCode, isNot(equals(other.hashCode)));
      });
    });

    group('toString', () {
      test('should return meaningful string representation', () {
        // Act
        final result = cachedComment.toString();

        // Assert
        expect(result, contains('CachedComment'));
        expect(result, contains('Test Commenter'));
        expect(result, contains('postId: 1'));
        expect(result, contains('needsSync: false'));
      });
    });
  });
}