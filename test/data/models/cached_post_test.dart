import 'package:flutter_test/flutter_test.dart';
import 'package:mini_feed/data/models/cached_post.dart';
import 'package:mini_feed/data/models/post_model.dart';
import 'package:mini_feed/domain/entities/post.dart';

void main() {
  group('CachedPost', () {
    late CachedPost cachedPost;
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2024, 1, 1, 12, 0, 0);
      
      cachedPost = CachedPost(
        id: 1,
        title: 'Test Post',
        body: 'This is a test post body.',
        userId: 1,
        isFavorite: true,
        isOptimistic: false,
        createdAt: testDate,
        updatedAt: testDate,
        cachedAt: testDate,
        needsSync: false,
        syncAttempts: 0,
      );
    });

    group('constructor', () {
      test('should create CachedPost with all fields', () {
        // Assert
        expect(cachedPost.id, equals(1));
        expect(cachedPost.title, equals('Test Post'));
        expect(cachedPost.body, equals('This is a test post body.'));
        expect(cachedPost.userId, equals(1));
        expect(cachedPost.isFavorite, isTrue);
        expect(cachedPost.isOptimistic, isFalse);
        expect(cachedPost.createdAt, equals(testDate));
        expect(cachedPost.updatedAt, equals(testDate));
        expect(cachedPost.cachedAt, equals(testDate));
        expect(cachedPost.needsSync, isFalse);
        expect(cachedPost.syncAttempts, equals(0));
      });

      test('should set default cachedAt when not provided', () {
        // Arrange
        final now = DateTime.now();
        
        // Act
        final result = CachedPost(
          id: 1,
          title: 'Test Post',
          body: 'Test body',
          userId: 1,
        );

        // Assert
        expect(result.cachedAt.difference(now).inSeconds, lessThan(1));
      });

      test('should set default values for optional fields', () {
        // Act
        final result = CachedPost(
          id: 1,
          title: 'Test Post',
          body: 'Test body',
          userId: 1,
        );

        // Assert
        expect(result.isFavorite, isFalse);
        expect(result.isOptimistic, isFalse);
        expect(result.needsSync, isFalse);
        expect(result.syncAttempts, equals(0));
        expect(result.syncError, isNull);
      });
    });

    group('toDomain', () {
      test('should convert to domain Post entity', () {
        // Act
        final result = cachedPost.toDomain();

        // Assert
        expect(result, isA<Post>());
        expect(result.id, equals(cachedPost.id));
        expect(result.title, equals(cachedPost.title));
        expect(result.body, equals(cachedPost.body));
        expect(result.userId, equals(cachedPost.userId));
        expect(result.isFavorite, equals(cachedPost.isFavorite));
        expect(result.isOptimistic, equals(cachedPost.isOptimistic));
        expect(result.createdAt, equals(cachedPost.createdAt));
        expect(result.updatedAt, equals(cachedPost.updatedAt));
      });
    });

    group('toModel', () {
      test('should convert to PostModel', () {
        // Act
        final result = cachedPost.toModel();

        // Assert
        expect(result, isA<PostModel>());
        expect(result.id, equals(cachedPost.id));
        expect(result.title, equals(cachedPost.title));
        expect(result.body, equals(cachedPost.body));
        expect(result.userId, equals(cachedPost.userId));
        expect(result.isFavorite, equals(cachedPost.isFavorite));
        expect(result.isOptimistic, equals(cachedPost.isOptimistic));
        expect(result.createdAt, equals(cachedPost.createdAt));
        expect(result.updatedAt, equals(cachedPost.updatedAt));
      });
    });

    group('fromDomain', () {
      test('should create CachedPost from domain Post entity', () {
        // Arrange
        const domainPost = Post(
          id: 2,
          title: 'Domain Post',
          body: 'Domain post body.',
          userId: 2,
          isFavorite: true,
        );

        // Act
        final result = CachedPost.fromDomain(domainPost);

        // Assert
        expect(result.id, equals(domainPost.id));
        expect(result.title, equals(domainPost.title));
        expect(result.body, equals(domainPost.body));
        expect(result.userId, equals(domainPost.userId));
        expect(result.isFavorite, equals(domainPost.isFavorite));
        expect(result.isOptimistic, equals(domainPost.isOptimistic));
        expect(result.needsSync, isFalse);
        expect(result.syncAttempts, equals(0));
      });

      test('should create CachedPost with sync metadata', () {
        // Arrange
        const domainPost = Post(
          id: 2,
          title: 'Domain Post',
          body: 'Domain post body.',
          userId: 2,
        );

        // Act
        final result = CachedPost.fromDomain(
          domainPost,
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
      test('should create CachedPost from PostModel', () {
        // Arrange
        final postModel = PostModel(
          id: 3,
          title: 'Model Post',
          body: 'Model post body.',
          userId: 3,
          isFavorite: false,
          createdAt: testDate,
        );

        // Act
        final result = CachedPost.fromModel(postModel);

        // Assert
        expect(result.id, equals(postModel.id));
        expect(result.title, equals(postModel.title));
        expect(result.body, equals(postModel.body));
        expect(result.userId, equals(postModel.userId));
        expect(result.isFavorite, equals(postModel.isFavorite));
        expect(result.createdAt, equals(postModel.createdAt));
      });
    });

    group('cache expiration', () {
      test('should detect expired cache', () {
        // Arrange
        final oldCachedPost = cachedPost.copyWith(
          cachedAt: DateTime.now().subtract(const Duration(hours: 2)),
        );

        // Act
        final isExpired = oldCachedPost.isExpired(const Duration(hours: 1));

        // Assert
        expect(isExpired, isTrue);
      });

      test('should detect non-expired cache', () {
        // Arrange
        final recentCachedPost = cachedPost.copyWith(
          cachedAt: DateTime.now().subtract(const Duration(minutes: 30)),
        );

        // Act
        final isExpired = recentCachedPost.isExpired(const Duration(hours: 1));

        // Assert
        expect(isExpired, isFalse);
      });

      test('should detect stale cache', () {
        // Arrange
        final staleCachedPost = cachedPost.copyWith(
          cachedAt: DateTime.now().subtract(const Duration(minutes: 45)),
        );

        // Act
        final isStale = staleCachedPost.isStale(const Duration(minutes: 30));

        // Assert
        expect(isStale, isTrue);
      });
    });

    group('copyWith', () {
      test('should create copy with updated fields', () {
        // Act
        final result = cachedPost.copyWith(
          title: 'Updated Title',
          needsSync: true,
          syncAttempts: 3,
        );

        // Assert
        expect(result.id, equals(cachedPost.id));
        expect(result.title, equals('Updated Title'));
        expect(result.body, equals(cachedPost.body));
        expect(result.needsSync, isTrue);
        expect(result.syncAttempts, equals(3));
        expect(result.userId, equals(cachedPost.userId));
      });

      test('should keep original values when no updates provided', () {
        // Act
        final result = cachedPost.copyWith();

        // Assert
        expect(result.id, equals(cachedPost.id));
        expect(result.title, equals(cachedPost.title));
        expect(result.body, equals(cachedPost.body));
        expect(result.needsSync, equals(cachedPost.needsSync));
        expect(result.syncAttempts, equals(cachedPost.syncAttempts));
      });
    });

    group('sync operations', () {
      test('should mark for sync', () {
        // Act
        final result = cachedPost.markForSync(error: 'Network error');

        // Assert
        expect(result.needsSync, isTrue);
        expect(result.syncError, equals('Network error'));
        expect(result.syncAttempts, equals(1));
      });

      test('should mark for sync without error', () {
        // Act
        final result = cachedPost.markForSync();

        // Assert
        expect(result.needsSync, isTrue);
        expect(result.syncError, isNull);
        expect(result.syncAttempts, equals(0));
      });

      test('should mark as synced', () {
        // Arrange
        final unsyncedPost = cachedPost.copyWith(
          needsSync: true,
          syncError: 'Error',
          syncAttempts: 2,
        );

        // Act
        final result = unsyncedPost.markAsSynced();

        // Assert
        expect(result.needsSync, isFalse);
        expect(result.syncError, isNull);
        expect(result.syncAttempts, equals(0));
        expect(result.cachedAt.isAfter(unsyncedPost.cachedAt), isTrue);
      });

      test('should determine if sync should be retried', () {
        // Arrange
        final failedPost = cachedPost.copyWith(
          needsSync: true,
          syncAttempts: 2,
        );

        // Act & Assert
        expect(failedPost.shouldRetrySync(maxAttempts: 3), isTrue);
        expect(failedPost.shouldRetrySync(maxAttempts: 2), isFalse);
      });

      test('should not retry sync when not needed', () {
        // Arrange
        final syncedPost = cachedPost.copyWith(needsSync: false);

        // Act & Assert
        expect(syncedPost.shouldRetrySync(), isFalse);
      });
    });

    group('favorite operations', () {
      test('should toggle favorite status', () {
        // Act
        final result = cachedPost.toggleFavorite();

        // Assert
        expect(result.isFavorite, isFalse);
        expect(result.needsSync, isTrue);
        expect(result.updatedAt!.isAfter(cachedPost.updatedAt!), isTrue);
      });
    });

    group('cache operations', () {
      test('should refresh cache timestamp', () {
        // Act
        final result = cachedPost.refreshCache();

        // Assert
        expect(result.cachedAt.isAfter(cachedPost.cachedAt), isTrue);
      });
    });

    group('cache age', () {
      test('should calculate cache age in minutes', () {
        // Arrange
        final oldPost = cachedPost.copyWith(
          cachedAt: DateTime.now().subtract(const Duration(minutes: 30)),
        );

        // Act
        final ageInMinutes = oldPost.cacheAgeInMinutes;

        // Assert
        expect(ageInMinutes, greaterThanOrEqualTo(29));
        expect(ageInMinutes, lessThanOrEqualTo(31));
      });

      test('should calculate cache age in hours', () {
        // Arrange
        final oldPost = cachedPost.copyWith(
          cachedAt: DateTime.now().subtract(const Duration(hours: 2)),
        );

        // Act
        final ageInHours = oldPost.cacheAgeInHours;

        // Assert
        expect(ageInHours, equals(2));
      });
    });

    group('equality and hashCode', () {
      test('should be equal when all properties are the same', () {
        // Arrange
        final other = CachedPost(
          id: 1,
          title: 'Test Post',
          body: 'This is a test post body.',
          userId: 1,
          isFavorite: true,
          isOptimistic: false,
          createdAt: testDate,
          updatedAt: testDate,
          cachedAt: testDate,
          needsSync: false,
          syncAttempts: 0,
        );

        // Assert
        expect(cachedPost, equals(other));
        expect(cachedPost.hashCode, equals(other.hashCode));
      });

      test('should not be equal when properties differ', () {
        // Arrange
        final other = cachedPost.copyWith(title: 'Different Title');

        // Assert
        expect(cachedPost, isNot(equals(other)));
        expect(cachedPost.hashCode, isNot(equals(other.hashCode)));
      });
    });

    group('toString', () {
      test('should return meaningful string representation', () {
        // Act
        final result = cachedPost.toString();

        // Assert
        expect(result, contains('CachedPost'));
        expect(result, contains('Test Post'));
        expect(result, contains('true')); // isFavorite
        expect(result, contains('false')); // isOptimistic and needsSync
      });
    });
  });
}