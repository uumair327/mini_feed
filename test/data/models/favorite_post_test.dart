import 'package:flutter_test/flutter_test.dart';
import 'package:mini_feed/data/models/favorite_post.dart';

void main() {
  group('FavoritePost', () {
    late FavoritePost favoritePost;
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2024, 1, 1, 12, 0, 0);
      
      favoritePost = FavoritePost(
        postId: 1,
        userId: 1,
        favoriteAt: testDate,
        needsSync: false,
        syncAttempts: 0,
      );
    });

    group('constructor', () {
      test('should create FavoritePost with all fields', () {
        // Assert
        expect(favoritePost.postId, equals(1));
        expect(favoritePost.userId, equals(1));
        expect(favoritePost.favoriteAt, equals(testDate));
        expect(favoritePost.needsSync, isFalse);
        expect(favoritePost.syncAttempts, equals(0));
        expect(favoritePost.syncError, isNull);
      });

      test('should set default favoriteAt when not provided', () {
        // Arrange
        final now = DateTime.now();
        
        // Act
        final result = FavoritePost(
          postId: 1,
          userId: 1,
        );

        // Assert
        expect(result.favoriteAt.difference(now).inSeconds, lessThan(1));
      });

      test('should set default values for optional fields', () {
        // Act
        final result = FavoritePost(
          postId: 1,
          userId: 1,
        );

        // Assert
        expect(result.needsSync, isFalse);
        expect(result.syncAttempts, equals(0));
        expect(result.syncError, isNull);
      });
    });

    group('copyWith', () {
      test('should create copy with updated fields', () {
        // Act
        final result = favoritePost.copyWith(
          needsSync: true,
          syncError: 'Network error',
          syncAttempts: 2,
        );

        // Assert
        expect(result.postId, equals(favoritePost.postId));
        expect(result.userId, equals(favoritePost.userId));
        expect(result.favoriteAt, equals(favoritePost.favoriteAt));
        expect(result.needsSync, isTrue);
        expect(result.syncError, equals('Network error'));
        expect(result.syncAttempts, equals(2));
      });

      test('should keep original values when no updates provided', () {
        // Act
        final result = favoritePost.copyWith();

        // Assert
        expect(result.postId, equals(favoritePost.postId));
        expect(result.userId, equals(favoritePost.userId));
        expect(result.favoriteAt, equals(favoritePost.favoriteAt));
        expect(result.needsSync, equals(favoritePost.needsSync));
        expect(result.syncAttempts, equals(favoritePost.syncAttempts));
        expect(result.syncError, equals(favoritePost.syncError));
      });
    });

    group('sync operations', () {
      test('should mark for sync', () {
        // Act
        final result = favoritePost.markForSync(error: 'Network error');

        // Assert
        expect(result.needsSync, isTrue);
        expect(result.syncError, equals('Network error'));
        expect(result.syncAttempts, equals(1));
      });

      test('should mark for sync without error', () {
        // Act
        final result = favoritePost.markForSync();

        // Assert
        expect(result.needsSync, isTrue);
        expect(result.syncError, isNull);
        expect(result.syncAttempts, equals(0));
      });

      test('should mark as synced', () {
        // Arrange
        final unsyncedFavorite = favoritePost.copyWith(
          needsSync: true,
          syncError: 'Error',
          syncAttempts: 2,
        );

        // Act
        final result = unsyncedFavorite.markAsSynced();

        // Assert
        expect(result.needsSync, isFalse);
        expect(result.syncError, isNull);
        expect(result.syncAttempts, equals(0));
      });

      test('should determine if sync should be retried', () {
        // Arrange
        final failedFavorite = favoritePost.copyWith(
          needsSync: true,
          syncAttempts: 2,
        );

        // Act & Assert
        expect(failedFavorite.shouldRetrySync(maxAttempts: 3), isTrue);
        expect(failedFavorite.shouldRetrySync(maxAttempts: 2), isFalse);
      });

      test('should not retry sync when not needed', () {
        // Arrange
        final syncedFavorite = favoritePost.copyWith(needsSync: false);

        // Act & Assert
        expect(syncedFavorite.shouldRetrySync(), isFalse);
      });
    });

    group('uniqueKey', () {
      test('should generate unique key from user and post IDs', () {
        // Act
        final uniqueKey = favoritePost.uniqueKey;

        // Assert
        expect(uniqueKey, equals('1_1'));
      });

      test('should generate different keys for different combinations', () {
        // Arrange
        final favorite1 = FavoritePost(postId: 1, userId: 2);
        final favorite2 = FavoritePost(postId: 2, userId: 1);

        // Act
        final key1 = favorite1.uniqueKey;
        final key2 = favorite2.uniqueKey;

        // Assert
        expect(key1, equals('2_1'));
        expect(key2, equals('1_2'));
        expect(key1, isNot(equals(key2)));
      });
    });

    group('create factory', () {
      test('should create FavoritePost with default sync needed', () {
        // Act
        final result = FavoritePost.create(
          postId: 5,
          userId: 3,
        );

        // Assert
        expect(result.postId, equals(5));
        expect(result.userId, equals(3));
        expect(result.needsSync, isTrue);
        expect(result.syncAttempts, equals(0));
        expect(result.syncError, isNull);
      });

      test('should create FavoritePost with custom sync status', () {
        // Act
        final result = FavoritePost.create(
          postId: 5,
          userId: 3,
          needsSync: false,
        );

        // Assert
        expect(result.postId, equals(5));
        expect(result.userId, equals(3));
        expect(result.needsSync, isFalse);
      });
    });

    group('equality and hashCode', () {
      test('should be equal when all properties are the same', () {
        // Arrange
        final other = FavoritePost(
          postId: 1,
          userId: 1,
          favoriteAt: testDate,
          needsSync: false,
          syncAttempts: 0,
        );

        // Assert
        expect(favoritePost, equals(other));
        expect(favoritePost.hashCode, equals(other.hashCode));
      });

      test('should not be equal when properties differ', () {
        // Arrange
        final other = favoritePost.copyWith(postId: 2);

        // Assert
        expect(favoritePost, isNot(equals(other)));
        expect(favoritePost.hashCode, isNot(equals(other.hashCode)));
      });
    });

    group('toString', () {
      test('should return meaningful string representation', () {
        // Act
        final result = favoritePost.toString();

        // Assert
        expect(result, contains('FavoritePost'));
        expect(result, contains('postId: 1'));
        expect(result, contains('userId: 1'));
        expect(result, contains('needsSync: false'));
      });
    });
  });
}