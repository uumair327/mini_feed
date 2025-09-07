import 'package:flutter_test/flutter_test.dart';
import 'package:mini_feed/data/models/cache_metadata.dart';

void main() {
  group('CacheMetadata', () {
    late CacheMetadata cacheMetadata;
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2024, 1, 1, 12, 0, 0);
      
      cacheMetadata = CacheMetadata(
        key: 'test_key',
        dataType: 'posts',
        createdAt: testDate,
        lastAccessedAt: testDate,
        expiresAt: testDate.add(const Duration(hours: 1)),
        accessCount: 5,
        sizeInBytes: 1024,
        tags: {'category': 'test', 'priority': 'high'},
        isPersistent: false,
        version: 1,
      );
    });

    group('constructor', () {
      test('should create CacheMetadata with all fields', () {
        // Assert
        expect(cacheMetadata.key, equals('test_key'));
        expect(cacheMetadata.dataType, equals('posts'));
        expect(cacheMetadata.createdAt, equals(testDate));
        expect(cacheMetadata.lastAccessedAt, equals(testDate));
        expect(cacheMetadata.expiresAt, equals(testDate.add(const Duration(hours: 1))));
        expect(cacheMetadata.accessCount, equals(5));
        expect(cacheMetadata.sizeInBytes, equals(1024));
        expect(cacheMetadata.tags['category'], equals('test'));
        expect(cacheMetadata.isPersistent, isFalse);
        expect(cacheMetadata.version, equals(1));
      });

      test('should set default values when not provided', () {
        // Arrange
        final now = DateTime.now();
        
        // Act
        final result = CacheMetadata(
          key: 'test_key',
          dataType: 'posts',
        );

        // Assert
        expect(result.createdAt.difference(now).inSeconds, lessThan(1));
        expect(result.lastAccessedAt.difference(now).inSeconds, lessThan(1));
        expect(result.accessCount, equals(0));
        expect(result.sizeInBytes, equals(0));
        expect(result.tags, isEmpty);
        expect(result.isPersistent, isFalse);
        expect(result.version, equals(1));
      });
    });

    group('expiration', () {
      test('should detect expired cache when expiresAt is in the past', () {
        // Arrange
        final expiredMetadata = cacheMetadata.copyWith(
          expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
        );

        // Act
        final isExpired = expiredMetadata.isExpired;

        // Assert
        expect(isExpired, isTrue);
      });

      test('should detect non-expired cache when expiresAt is in the future', () {
        // Arrange
        final validMetadata = cacheMetadata.copyWith(
          expiresAt: DateTime.now().add(const Duration(hours: 1)),
        );

        // Act
        final isExpired = validMetadata.isExpired;

        // Assert
        expect(isExpired, isFalse);
      });

      test('should not be expired when expiresAt is null', () {
        // Arrange
        final neverExpiresMetadata = CacheMetadata(
          key: cacheMetadata.key,
          dataType: cacheMetadata.dataType,
          createdAt: cacheMetadata.createdAt,
          lastAccessedAt: cacheMetadata.lastAccessedAt,
          expiresAt: null,
          accessCount: cacheMetadata.accessCount,
          sizeInBytes: cacheMetadata.sizeInBytes,
          tags: cacheMetadata.tags,
          isPersistent: cacheMetadata.isPersistent,
          version: cacheMetadata.version,
        );

        // Act
        final isExpired = neverExpiresMetadata.isExpired;

        // Assert
        expect(isExpired, isFalse);
      });
    });

    group('staleness', () {
      test('should detect stale cache', () {
        // Arrange
        final staleMetadata = cacheMetadata.copyWith(
          lastAccessedAt: DateTime.now().subtract(const Duration(hours: 2)),
        );

        // Act
        final isStale = staleMetadata.isStale(const Duration(hours: 1));

        // Assert
        expect(isStale, isTrue);
      });

      test('should detect non-stale cache', () {
        // Arrange
        final freshMetadata = cacheMetadata.copyWith(
          lastAccessedAt: DateTime.now().subtract(const Duration(minutes: 30)),
        );

        // Act
        final isStale = freshMetadata.isStale(const Duration(hours: 1));

        // Assert
        expect(isStale, isFalse);
      });
    });

    group('age calculations', () {
      test('should calculate age correctly', () {
        // Arrange
        final oldMetadata = cacheMetadata.copyWith(
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        );

        // Act
        final age = oldMetadata.age;

        // Assert
        expect(age.inHours, equals(2));
      });

      test('should calculate time since last access correctly', () {
        // Arrange
        final metadata = cacheMetadata.copyWith(
          lastAccessedAt: DateTime.now().subtract(const Duration(minutes: 30)),
        );

        // Act
        final timeSinceAccess = metadata.timeSinceLastAccess;

        // Assert
        expect(timeSinceAccess.inMinutes, greaterThanOrEqualTo(29));
        expect(timeSinceAccess.inMinutes, lessThanOrEqualTo(31));
      });
    });

    group('copyWith', () {
      test('should create copy with updated fields', () {
        // Act
        final result = cacheMetadata.copyWith(
          key: 'new_key',
          accessCount: 10,
          isPersistent: true,
        );

        // Assert
        expect(result.key, equals('new_key'));
        expect(result.dataType, equals(cacheMetadata.dataType));
        expect(result.accessCount, equals(10));
        expect(result.isPersistent, isTrue);
        expect(result.version, equals(cacheMetadata.version));
      });

      test('should keep original values when no updates provided', () {
        // Act
        final result = cacheMetadata.copyWith();

        // Assert
        expect(result.key, equals(cacheMetadata.key));
        expect(result.dataType, equals(cacheMetadata.dataType));
        expect(result.accessCount, equals(cacheMetadata.accessCount));
        expect(result.isPersistent, equals(cacheMetadata.isPersistent));
      });
    });

    group('access operations', () {
      test('should update access information', () {
        // Arrange
        final now = DateTime.now();

        // Act
        final result = cacheMetadata.updateAccess();

        // Assert
        expect(result.accessCount, equals(cacheMetadata.accessCount + 1));
        expect(result.lastAccessedAt.isAfter(cacheMetadata.lastAccessedAt), isTrue);
        expect(result.lastAccessedAt.difference(now).inSeconds, lessThan(1));
      });

      test('should update expiration time', () {
        // Arrange
        final newExpiration = DateTime.now().add(const Duration(hours: 2));

        // Act
        final result = cacheMetadata.updateExpiration(newExpiration);

        // Assert
        expect(result.expiresAt, equals(newExpiration));
      });
    });

    group('tag operations', () {
      test('should add new tag', () {
        // Act
        final result = cacheMetadata.addTag('newTag', 'newValue');

        // Assert
        expect(result.tags['newTag'], equals('newValue'));
        expect(result.tags['category'], equals('test')); // Original tag preserved
      });

      test('should update existing tag', () {
        // Act
        final result = cacheMetadata.addTag('category', 'updated');

        // Assert
        expect(result.tags['category'], equals('updated'));
        expect(result.tags['priority'], equals('high')); // Other tag preserved
      });

      test('should remove tag', () {
        // Act
        final result = cacheMetadata.removeTag('category');

        // Assert
        expect(result.tags.containsKey('category'), isFalse);
        expect(result.tags['priority'], equals('high')); // Other tag preserved
      });

      test('should check if has tag', () {
        // Act & Assert
        expect(cacheMetadata.hasTag('category'), isTrue);
        expect(cacheMetadata.hasTag('nonexistent'), isFalse);
      });

      test('should get tag value', () {
        // Act & Assert
        expect(cacheMetadata.getTag<String>('category'), equals('test'));
        expect(cacheMetadata.getTag<String>('nonexistent'), isNull);
      });
    });

    group('factory constructors', () {
      test('should create metadata for posts', () {
        // Act
        final result = CacheMetadata.forPosts(
          key: 'posts_key',
          maxAge: const Duration(hours: 1),
          tags: {'source': 'api'},
          isPersistent: true,
        );

        // Assert
        expect(result.key, equals('posts_key'));
        expect(result.dataType, equals('posts'));
        expect(result.expiresAt, isNotNull);
        expect(result.tags['source'], equals('api'));
        expect(result.isPersistent, isTrue);
      });

      test('should create metadata for comments', () {
        // Act
        final result = CacheMetadata.forComments(
          key: 'comments_key',
          maxAge: const Duration(minutes: 30),
        );

        // Assert
        expect(result.key, equals('comments_key'));
        expect(result.dataType, equals('comments'));
        expect(result.expiresAt, isNotNull);
      });

      test('should create metadata for users', () {
        // Act
        final result = CacheMetadata.forUsers(
          key: 'users_key',
        );

        // Assert
        expect(result.key, equals('users_key'));
        expect(result.dataType, equals('users'));
      });

      test('should create metadata for search', () {
        // Act
        final result = CacheMetadata.forSearch(
          key: 'search_key',
          query: 'test query',
          maxAge: const Duration(minutes: 5),
        );

        // Assert
        expect(result.key, equals('search_key'));
        expect(result.dataType, equals('search'));
        expect(result.tags['query'], equals('test query'));
      });
    });

    group('getStats', () {
      test('should return comprehensive statistics', () {
        // Act
        final stats = cacheMetadata.getStats();

        // Assert
        expect(stats['key'], equals('test_key'));
        expect(stats['dataType'], equals('posts'));
        expect(stats['accessCount'], equals(5));
        expect(stats['sizeInBytes'], equals(1024));
        expect(stats['isPersistent'], isFalse);
        expect(stats['version'], equals(1));
        expect(stats['tags'], isA<Map<String, dynamic>>());
        expect(stats.containsKey('age'), isTrue);
        expect(stats.containsKey('timeSinceLastAccess'), isTrue);
        expect(stats.containsKey('isExpired'), isTrue);
      });
    });

    group('equality and hashCode', () {
      test('should be equal when all properties are the same', () {
        // Arrange
        final other = CacheMetadata(
          key: 'test_key',
          dataType: 'posts',
          createdAt: testDate,
          lastAccessedAt: testDate,
          expiresAt: testDate.add(const Duration(hours: 1)),
          accessCount: 5,
          sizeInBytes: 1024,
          isPersistent: false,
          version: 1,
        );

        // Assert
        expect(cacheMetadata, equals(other));
        expect(cacheMetadata.hashCode, equals(other.hashCode));
      });

      test('should not be equal when properties differ', () {
        // Arrange
        final other = cacheMetadata.copyWith(key: 'different_key');

        // Assert
        expect(cacheMetadata, isNot(equals(other)));
        expect(cacheMetadata.hashCode, isNot(equals(other.hashCode)));
      });
    });

    group('toString', () {
      test('should return meaningful string representation', () {
        // Act
        final result = cacheMetadata.toString();

        // Assert
        expect(result, contains('CacheMetadata'));
        expect(result, contains('test_key'));
        expect(result, contains('posts'));
        expect(result, contains('accessCount: 5'));
      });
    });
  });
}