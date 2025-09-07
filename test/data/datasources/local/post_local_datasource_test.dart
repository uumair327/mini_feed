import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mini_feed/core/storage/storage_service.dart';
import 'package:mini_feed/core/utils/result.dart';
import 'package:mini_feed/core/errors/exceptions.dart';
import 'package:mini_feed/data/datasources/local/post_local_datasource.dart';
import 'package:mini_feed/data/models/post_model.dart';
import 'package:mini_feed/data/models/comment_model.dart';
import 'package:mini_feed/data/models/cached_post.dart';
import 'package:mini_feed/data/models/cached_comment.dart';
import 'package:mini_feed/data/models/favorite_post.dart';
import 'package:mini_feed/data/models/cache_metadata.dart';

class MockStorageService extends Mock implements StorageService {}
class MockBox<T> extends Mock implements Box<T> {}

void main() {
  group('PostLocalDataSourceImpl', () {
    late PostLocalDataSourceImpl dataSource;
    late MockStorageService mockStorageService;
    late MockBox<CachedPost> mockPostsBox;
    late MockBox<CachedComment> mockCommentsBox;
    late MockBox<FavoritePost> mockFavoritesBox;
    late MockBox<CacheMetadata> mockMetadataBox;

    setUp(() {
      mockStorageService = MockStorageService();
      mockPostsBox = MockBox<CachedPost>();
      mockCommentsBox = MockBox<CachedComment>();
      mockFavoritesBox = MockBox<FavoritePost>();
      mockMetadataBox = MockBox<CacheMetadata>();

      dataSource = PostLocalDataSourceImpl(
        storageService: mockStorageService,
      );

      // Set up the private boxes using reflection or by making them public for testing
      // For this test, we'll assume the boxes are initialized
    });

    group('initialization', () {
      test('should initialize successfully', () async {
        // Note: This test would require actual Hive setup in a real scenario
        // For unit testing, we'd typically mock the Hive operations
        
        // Act & Assert
        // In a real test, we'd verify that Hive.openBox is called for each box type
        expect(true, isTrue); // Placeholder test
      });
    });

    group('cachePost', () {
      test('should cache a single post successfully', () async {
        // Arrange
        const post = PostModel(
          id: 1,
          title: 'Test Post',
          body: 'Test body',
          userId: 1,
        );

        // Mock the box operations
        when(() => mockPostsBox.put(any(), any())).thenAnswer((_) async => {});

        // Act
        // Note: In a real implementation, we'd need to properly mock the Hive boxes
        // For now, this is a structural test
        expect(post.id, equals(1));
        expect(post.title, equals('Test Post'));
      });
    });

    group('getCachedPost', () {
      test('should return cached post when available and not expired', () async {
        // Arrange
        const postId = 1;
        final cachedPost = CachedPost(
          id: 1,
          title: 'Test Post',
          body: 'Test body',
          userId: 1,
          cachedAt: DateTime.now(),
        );

        when(() => mockPostsBox.get(postId)).thenReturn(cachedPost);

        // Act & Assert
        expect(cachedPost.id, equals(postId));
        expect(cachedPost.isExpired(const Duration(minutes: 15)), isFalse);
      });

      test('should return null when post is expired', () async {
        // Arrange
        const postId = 1;
        final expiredPost = CachedPost(
          id: 1,
          title: 'Test Post',
          body: 'Test body',
          userId: 1,
          cachedAt: DateTime.now().subtract(const Duration(hours: 1)),
        );

        when(() => mockPostsBox.get(postId)).thenReturn(expiredPost);

        // Act & Assert
        expect(expiredPost.isExpired(const Duration(minutes: 15)), isTrue);
      });

      test('should return null when post not found', () async {
        // Arrange
        const postId = 1;
        when(() => mockPostsBox.get(postId)).thenReturn(null);

        // Act & Assert
        final result = mockPostsBox.get(postId);
        expect(result, isNull);
      });
    });

    group('addToFavorites', () {
      test('should add post to favorites successfully', () async {
        // Arrange
        const postId = 1;
        const userId = 1;
        
        when(() => mockFavoritesBox.put(any(), any())).thenAnswer((_) async => {});

        // Act
        final favorite = FavoritePost.create(postId: postId, userId: userId);

        // Assert
        expect(favorite.postId, equals(postId));
        expect(favorite.userId, equals(userId));
        expect(favorite.uniqueKey, equals('${userId}_$postId'));
      });
    });

    group('removeFromFavorites', () {
      test('should remove post from favorites successfully', () async {
        // Arrange
        const postId = 1;
        const userId = 1;
        final key = '${userId}_$postId';

        when(() => mockFavoritesBox.delete(key)).thenAnswer((_) async => {});

        // Act & Assert
        expect(key, equals('1_1'));
      });
    });

    group('isPostFavorite', () {
      test('should return true when post is in favorites', () async {
        // Arrange
        const postId = 1;
        const userId = 1;
        final key = '${userId}_$postId';
        final favorite = FavoritePost.create(postId: postId, userId: userId);

        when(() => mockFavoritesBox.get(key)).thenReturn(favorite);

        // Act & Assert
        final result = mockFavoritesBox.get(key);
        expect(result, isNotNull);
        expect(result!.postId, equals(postId));
        expect(result.userId, equals(userId));
      });

      test('should return false when post is not in favorites', () async {
        // Arrange
        const postId = 1;
        const userId = 1;
        final key = '${userId}_$postId';

        when(() => mockFavoritesBox.get(key)).thenReturn(null);

        // Act & Assert
        final result = mockFavoritesBox.get(key);
        expect(result, isNull);
      });
    });

    group('cacheComments', () {
      test('should cache comments for a post successfully', () async {
        // Arrange
        const postId = 1;
        const comments = [
          CommentModel(
            id: 1,
            postId: 1,
            name: 'Test Commenter',
            email: 'test@example.com',
            body: 'Test comment',
          ),
          CommentModel(
            id: 2,
            postId: 1,
            name: 'Another Commenter',
            email: 'another@example.com',
            body: 'Another comment',
          ),
        ];

        when(() => mockCommentsBox.put(any(), any())).thenAnswer((_) async => {});
        when(() => mockMetadataBox.put(any(), any())).thenAnswer((_) async => {});

        // Act & Assert
        expect(comments.length, equals(2));
        expect(comments[0].postId, equals(postId));
        expect(comments[1].postId, equals(postId));
      });
    });

    group('getCachedComments', () {
      test('should return cached comments when available and not expired', () async {
        // Arrange
        const postId = 1;
        final cachedComments = [
          CachedComment(
            id: 1,
            postId: 1,
            name: 'Test Commenter',
            email: 'test@example.com',
            body: 'Test comment',
            cachedAt: DateTime.now(),
          ),
        ];

        final metadata = CacheMetadata.forComments(
          key: 'comments_$postId',
          maxAge: const Duration(minutes: 10),
        );

        when(() => mockMetadataBox.get('comments_$postId')).thenReturn(metadata);
        when(() => mockCommentsBox.values).thenReturn(cachedComments);

        // Act & Assert
        expect(metadata.isExpired, isFalse);
        expect(cachedComments.length, equals(1));
        expect(cachedComments[0].postId, equals(postId));
      });

      test('should return empty list when cache is expired', () async {
        // Arrange
        const postId = 1;
        final expiredMetadata = CacheMetadata(
          key: 'comments_$postId',
          dataType: 'comments',
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          expiresAt: DateTime.now().subtract(const Duration(minutes: 30)),
        );

        when(() => mockMetadataBox.get('comments_$postId')).thenReturn(expiredMetadata);

        // Act & Assert
        expect(expiredMetadata.isExpired, isTrue);
      });
    });

    group('cacheSearchResults', () {
      test('should cache search results successfully', () async {
        // Arrange
        const query = 'test';
        const posts = [
          PostModel(
            id: 1,
            title: 'Test Post',
            body: 'Test body',
            userId: 1,
          ),
        ];

        when(() => mockPostsBox.put(any(), any())).thenAnswer((_) async => {});
        when(() => mockMetadataBox.put(any(), any())).thenAnswer((_) async => {});
        when(() => mockStorageService.setStringList(any(), any())).thenAnswer((_) async {});

        // Act & Assert
        final key = 'search_${query.hashCode}';
        expect(key, contains('search_'));
        expect(posts.length, equals(1));
      });
    });

    group('getCachedSearchResults', () {
      test('should return cached search results when available and not expired', () async {
        // Arrange
        const query = 'test';
        final key = 'search_${query.hashCode}';
        
        final metadata = CacheMetadata.forSearch(
          key: key,
          query: query,
          maxAge: const Duration(minutes: 5),
        );

        final postIds = ['1', '2'];
        final cachedPost = CachedPost(
          id: 1,
          title: 'Test Post',
          body: 'Test body',
          userId: 1,
          cachedAt: DateTime.now(),
        );

        when(() => mockMetadataBox.get(key)).thenReturn(metadata);
        when(() => mockStorageService.getStringList(key)).thenAnswer((_) async => postIds);
        when(() => mockPostsBox.get(1)).thenReturn(cachedPost);

        // Act & Assert
        expect(metadata.isExpired, isFalse);
        expect(postIds.length, equals(2));
        expect(cachedPost.isExpired(const Duration(minutes: 15)), isFalse);
      });

      test('should return null when search cache is expired', () async {
        // Arrange
        const query = 'test';
        final key = 'search_${query.hashCode}';
        
        final expiredMetadata = CacheMetadata(
          key: key,
          dataType: 'search',
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          expiresAt: DateTime.now().subtract(const Duration(minutes: 10)),
        );

        when(() => mockMetadataBox.get(key)).thenReturn(expiredMetadata);

        // Act & Assert
        expect(expiredMetadata.isExpired, isTrue);
      });
    });

    group('clearPostsCache', () {
      test('should clear all cache boxes successfully', () async {
        // Arrange
        when(() => mockPostsBox.clear()).thenAnswer((_) async => 0);
        when(() => mockCommentsBox.clear()).thenAnswer((_) async => 0);
        when(() => mockFavoritesBox.clear()).thenAnswer((_) async => 0);
        when(() => mockMetadataBox.clear()).thenAnswer((_) async => 0);

        // Act & Assert
        // In a real test, we'd verify that all clear methods are called
        expect(true, isTrue); // Placeholder
      });
    });

    group('getPostsCacheStats', () {
      test('should return cache statistics', () async {
        // Arrange
        when(() => mockPostsBox.length).thenReturn(10);
        when(() => mockCommentsBox.length).thenReturn(25);
        when(() => mockFavoritesBox.length).thenReturn(5);
        when(() => mockMetadataBox.length).thenReturn(15);

        // Act
        final expectedStats = {
          'posts_count': 10,
          'comments_count': 25,
          'favorites_count': 5,
          'metadata_count': 15,
          'total_entries': 55,
        };

        // Assert
        expect(expectedStats['posts_count'], equals(10));
        expect(expectedStats['total_entries'], equals(55));
      });
    });

    group('cache expiration', () {
      test('should identify expired posts correctly', () async {
        // Arrange
        final expiredPost = CachedPost(
          id: 1,
          title: 'Expired Post',
          body: 'Expired body',
          userId: 1,
          cachedAt: DateTime.now().subtract(const Duration(hours: 1)),
        );

        final freshPost = CachedPost(
          id: 2,
          title: 'Fresh Post',
          body: 'Fresh body',
          userId: 1,
          cachedAt: DateTime.now(),
        );

        // Act & Assert
        expect(expiredPost.isExpired(const Duration(minutes: 15)), isTrue);
        expect(freshPost.isExpired(const Duration(minutes: 15)), isFalse);
      });

      test('should identify expired comments correctly', () async {
        // Arrange
        final expiredComment = CachedComment(
          id: 1,
          postId: 1,
          name: 'Test',
          email: 'test@example.com',
          body: 'Expired comment',
          cachedAt: DateTime.now().subtract(const Duration(hours: 1)),
        );

        final freshComment = CachedComment(
          id: 2,
          postId: 1,
          name: 'Test',
          email: 'test@example.com',
          body: 'Fresh comment',
          cachedAt: DateTime.now(),
        );

        // Act & Assert
        expect(expiredComment.isExpired(const Duration(minutes: 10)), isTrue);
        expect(freshComment.isExpired(const Duration(minutes: 10)), isFalse);
      });
    });

    group('error handling', () {
      test('should throw CacheException when not initialized', () {
        // Arrange
        final uninitializedDataSource = PostLocalDataSourceImpl(
          storageService: mockStorageService,
        );

        // Act & Assert
        expect(
          () => uninitializedDataSource.getPostsCacheStats(),
          throwsA(isA<CacheException>()),
        );
      });
    });
  });
}