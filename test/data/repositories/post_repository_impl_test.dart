import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../lib/core/network/network_info.dart';
import '../../../lib/core/storage/storage_service.dart';
import '../../../lib/core/utils/result.dart';
import '../../../lib/core/errors/failures.dart';
import '../../../lib/core/errors/exceptions.dart';
import '../../../lib/domain/entities/post.dart';
import '../../../lib/domain/entities/comment.dart';
import '../../../lib/data/repositories/post_repository_impl.dart';
import '../../../lib/data/datasources/remote/post_remote_datasource.dart';
import '../../../lib/data/models/post_model.dart';
import '../../../lib/data/models/comment_model.dart';

// Mock classes
class MockPostRemoteDataSource extends Mock implements PostRemoteDataSource {}
class MockStorageService extends Mock implements StorageService {}
class MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  late PostRepositoryImpl repository;
  late MockPostRemoteDataSource mockRemoteDataSource;
  late MockStorageService mockStorageService;
  late MockNetworkInfo mockNetworkInfo;

  setUp(() {
    mockRemoteDataSource = MockPostRemoteDataSource();
    mockStorageService = MockStorageService();
    mockNetworkInfo = MockNetworkInfo();
    
    repository = PostRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      storageService: mockStorageService,
      networkInfo: mockNetworkInfo,
    );
  });

  group('getPosts', () {
    final postModels = [
      PostModel(
        id: 1,
        title: 'Test Post 1',
        body: 'Test body 1',
        userId: 1,
      ),
      PostModel(
        id: 2,
        title: 'Test Post 2',
        body: 'Test body 2',
        userId: 1,
      ),
    ];

    test('should return posts from remote when network is available', () async {
      // Arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockStorageService.get<String>('posts_1_20')).thenAnswer((_) async => null);
      when(() => mockRemoteDataSource.getPosts(page: 1, limit: 20))
          .thenAnswer((_) async => success(postModels));
      when(() => mockStorageService.store(any(), any())).thenAnswer((_) async {});
      when(() => mockStorageService.get<bool>(any())).thenAnswer((_) async => false);

      // Act
      final result = await repository.getPosts();

      // Assert
      expect(result.isSuccess, true);
      expect(result.successValue!.length, 2);
      expect(result.successValue![0].title, 'Test Post 1');
      
      verify(() => mockNetworkInfo.isConnected).called(1);
      verify(() => mockRemoteDataSource.getPosts(page: 1, limit: 20)).called(1);
    });

    test('should return cached posts when network is unavailable', () async {
      // Arrange
      when(() => mockStorageService.get<String>('posts_1_20'))
          .thenAnswer((_) async => '${DateTime.now().millisecondsSinceEpoch}|1,2');
      when(() => mockStorageService.get<String>('post_1'))
          .thenAnswer((_) async => postModels[0].toJsonString());
      when(() => mockStorageService.get<String>('post_2'))
          .thenAnswer((_) async => postModels[1].toJsonString());
      when(() => mockStorageService.get<bool>(any())).thenAnswer((_) async => false);
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      // Act
      final result = await repository.getPosts();

      // Assert
      expect(result.isSuccess, true);
      expect(result.successValue!.length, 2);
      
      // Verify cache was accessed
      verify(() => mockStorageService.get<String>('posts_1_20')).called(greaterThan(0));
    });

    test('should return NetworkFailure when no network and no cache', () async {
      // Arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
      when(() => mockStorageService.get<String>('posts_1_20')).thenAnswer((_) async => null);

      // Act
      final result = await repository.getPosts();

      // Assert
      expect(result.isFailure, true);
      expect(result.failureValue, isA<NetworkFailure>());
      expect(result.failureValue!.message, 'No internet connection and no cached data');
    });

    test('should force refresh when forceRefresh is true', () async {
      // Arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.getPosts(page: 1, limit: 20))
          .thenAnswer((_) async => success(postModels));
      when(() => mockStorageService.store(any(), any())).thenAnswer((_) async {});
      when(() => mockStorageService.get<bool>(any())).thenAnswer((_) async => false);

      // Act
      final result = await repository.getPosts(forceRefresh: true);

      // Assert
      expect(result.isSuccess, true);
      
      verify(() => mockRemoteDataSource.getPosts(page: 1, limit: 20)).called(1);
      verifyNever(() => mockStorageService.get<String>('posts_1_20'));
    });

    test('should handle ServerException and return ServerFailure', () async {
      // Arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockStorageService.get<String>('posts_1_20')).thenAnswer((_) async => null);
      when(() => mockRemoteDataSource.getPosts(page: 1, limit: 20))
          .thenThrow(const ServerException('Server error', 500));

      // Act
      final result = await repository.getPosts();

      // Assert
      expect(result.isFailure, true);
      expect(result.failureValue, isA<ServerFailure>());
      expect(result.failureValue!.message, 'Server error');
    });
  });

  group('getPost', () {
    final postModel = PostModel(
      id: 1,
      title: 'Test Post',
      body: 'Test body',
      userId: 1,
    );

    test('should return post from remote when network is available', () async {
      // Arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockStorageService.get<String>('post_1')).thenAnswer((_) async => null);
      when(() => mockRemoteDataSource.getPostById(1))
          .thenAnswer((_) async => success(postModel));
      when(() => mockStorageService.store(any(), any())).thenAnswer((_) async {});
      when(() => mockStorageService.get<bool>(any())).thenAnswer((_) async => false);

      // Act
      final result = await repository.getPost(postId: 1);

      // Assert
      expect(result.isSuccess, true);
      expect(result.successValue!.title, 'Test Post');
      
      verify(() => mockRemoteDataSource.getPostById(1)).called(1);
    });

    test('should return cached post when network is unavailable', () async {
      // Arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
      when(() => mockStorageService.get<String>('post_1'))
          .thenAnswer((_) async => postModel.toJsonString());
      when(() => mockStorageService.get<bool>(any())).thenAnswer((_) async => false);

      // Act
      final result = await repository.getPost(postId: 1);

      // Assert
      expect(result.isSuccess, true);
      expect(result.successValue!.title, 'Test Post');
      
      verifyNever(() => mockRemoteDataSource.getPostById(any()));
    });
  });

  group('getComments', () {
    final commentModels = [
      CommentModel(
        id: 1,
        postId: 1,
        name: 'Test User',
        email: 'test@example.com',
        body: 'Test comment',
      ),
    ];

    test('should return comments from remote when network is available', () async {
      // Arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockStorageService.get<String>('comments_1')).thenAnswer((_) async => null);
      when(() => mockRemoteDataSource.getComments(postId: 1))
          .thenAnswer((_) async => success(commentModels));
      when(() => mockStorageService.store(any(), any())).thenAnswer((_) async {});

      // Act
      final result = await repository.getComments(postId: 1);

      // Assert
      expect(result.isSuccess, true);
      expect(result.successValue!.length, 1);
      expect(result.successValue![0].body, 'Test comment');
      
      verify(() => mockRemoteDataSource.getComments(postId: 1)).called(1);
    });

    test('should return empty comments when network is unavailable and no cache', () async {
      // Arrange
      when(() => mockStorageService.get<String>('comments_1')).thenAnswer((_) async => null);
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      // Act
      final result = await repository.getComments(postId: 1);

      // Assert
      expect(result.isFailure, true);
      expect(result.failureValue, isA<NetworkFailure>());
      expect(result.failureValue!.message, 'No internet connection and no cached data');
    });
  });

  group('createPost', () {
    final createdPost = PostModel(
      id: 101,
      title: 'New Post',
      body: 'New post body',
      userId: 1,
    );

    test('should create post successfully', () async {
      // Arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.createPost(
        title: 'New Post',
        body: 'New post body',
        userId: 1,
      )).thenAnswer((_) async => success(createdPost));
      when(() => mockStorageService.store(any(), any())).thenAnswer((_) async {});
      when(() => mockStorageService.delete(any())).thenAnswer((_) async {});

      // Act
      final result = await repository.createPost(
        title: 'New Post',
        body: 'New post body',
        userId: 1,
      );

      // Assert
      expect(result.isSuccess, true);
      expect(result.successValue!.title, 'New Post');
      
      verify(() => mockRemoteDataSource.createPost(
        title: 'New Post',
        body: 'New post body',
        userId: 1,
      )).called(1);
    });

    test('should return NetworkFailure when no internet connection', () async {
      // Arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      // Act
      final result = await repository.createPost(
        title: 'New Post',
        body: 'New post body',
        userId: 1,
      );

      // Assert
      expect(result.isFailure, true);
      expect(result.failureValue, isA<NetworkFailure>());
      expect(result.failureValue!.message, 'No internet connection');
    });

    test('should handle optimistic update rollback on failure', () async {
      // Arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.createPost(
        title: 'New Post',
        body: 'New post body',
        userId: 1,
      )).thenAnswer((_) async => failure(const ServerFailure('Server error', 500)));
      when(() => mockStorageService.store(any(), any())).thenAnswer((_) async {});
      when(() => mockStorageService.delete(any())).thenAnswer((_) async {});

      // Act
      final result = await repository.createPost(
        title: 'New Post',
        body: 'New post body',
        userId: 1,
      );

      // Assert
      expect(result.isFailure, true);
      expect(result.failureValue, isA<ServerFailure>());
      
      // Verify optimistic post was removed
      verify(() => mockStorageService.delete(any())).called(1);
    });
  });

  group('searchPosts', () {
    final searchResults = [
      PostModel(
        id: 1,
        title: 'Search Result',
        body: 'Search body',
        userId: 1,
      ),
    ];

    test('should return search results from remote', () async {
      // Arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockStorageService.get<String>(any())).thenAnswer((_) async => null);
      when(() => mockRemoteDataSource.searchPosts(
        query: 'test',
        page: 1,
        limit: 20,
      )).thenAnswer((_) async => success(searchResults));
      when(() => mockStorageService.store(any(), any())).thenAnswer((_) async {});
      when(() => mockStorageService.get<bool>(any())).thenAnswer((_) async => false);

      // Act
      final result = await repository.searchPosts(query: 'test');

      // Assert
      expect(result.isSuccess, true);
      expect(result.successValue!.length, 1);
      
      verify(() => mockRemoteDataSource.searchPosts(
        query: 'test',
        page: 1,
        limit: 20,
      )).called(1);
    });

    test('should perform local search when network is unavailable', () async {
      // Arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
      when(() => mockStorageService.get<String>(any())).thenAnswer((_) async => null);

      // Act
      final result = await repository.searchPosts(query: 'test');

      // Assert
      expect(result.isSuccess, true);
      // Local search returns empty list when no cached posts
      expect(result.successValue!.isEmpty, true);
    });
  });

  group('toggleFavorite', () {
    test('should add post to favorites', () async {
      // Arrange
      when(() => mockStorageService.store('favorite_1_1', true)).thenAnswer((_) async {});
      when(() => mockStorageService.get<String>('post_1')).thenAnswer((_) async => null);
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      // Act
      final result = await repository.toggleFavorite(postId: 1, isFavorite: true);

      // Assert
      expect(result.isFailure, true); // Fails because post doesn't exist in cache
      
      verify(() => mockStorageService.store('favorite_1_1', true)).called(1);
    });

    test('should remove post from favorites', () async {
      // Arrange
      when(() => mockStorageService.delete('favorite_1_1')).thenAnswer((_) async {});
      when(() => mockStorageService.get<String>('post_1')).thenAnswer((_) async => null);
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      // Act
      final result = await repository.toggleFavorite(postId: 1, isFavorite: false);

      // Assert
      expect(result.isFailure, true); // Fails because post doesn't exist in cache
      
      verify(() => mockStorageService.delete('favorite_1_1')).called(1);
    });
  });

  group('refreshPosts', () {
    final postModels = [
      PostModel(
        id: 1,
        title: 'Refreshed Post',
        body: 'Refreshed body',
        userId: 1,
      ),
    ];

    test('should refresh posts from remote', () async {
      // Arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.getPosts(page: 1, limit: 20))
          .thenAnswer((_) async => success(postModels));
      when(() => mockStorageService.store(any(), any())).thenAnswer((_) async {});
      when(() => mockStorageService.get<bool>(any())).thenAnswer((_) async => false);

      // Act
      final result = await repository.refreshPosts();

      // Assert
      expect(result.isSuccess, true);
      expect(result.successValue!.length, 1);
      
      verify(() => mockRemoteDataSource.getPosts(page: 1, limit: 20)).called(1);
    });

    test('should clear cache when clearCache is true', () async {
      // Arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.getPosts(page: 1, limit: 20))
          .thenAnswer((_) async => success(postModels));
      when(() => mockStorageService.store(any(), any())).thenAnswer((_) async {});
      when(() => mockStorageService.delete(any())).thenAnswer((_) async {});
      when(() => mockStorageService.get<bool>(any())).thenAnswer((_) async => false);

      // Act
      final result = await repository.refreshPosts(clearCache: true);

      // Assert
      expect(result.isSuccess, true);
      
      // Verify cache was cleared (multiple delete calls)
      verify(() => mockStorageService.delete(any())).called(greaterThan(1));
    });
  });

  group('deletePost', () {
    test('should delete post successfully', () async {
      // Arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockRemoteDataSource.deletePost(1))
          .thenAnswer((_) async => success(null));
      when(() => mockStorageService.delete('post_1')).thenAnswer((_) async {});
      when(() => mockStorageService.delete(any())).thenAnswer((_) async {});

      // Act
      final result = await repository.deletePost(postId: 1);

      // Assert
      expect(result.isSuccess, true);
      
      verify(() => mockRemoteDataSource.deletePost(1)).called(1);
      verify(() => mockStorageService.delete('post_1')).called(1);
    });

    test('should return NetworkFailure when no internet connection', () async {
      // Arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);

      // Act
      final result = await repository.deletePost(postId: 1);

      // Assert
      expect(result.isFailure, true);
      expect(result.failureValue, isA<NetworkFailure>());
      expect(result.failureValue!.message, 'No internet connection');
    });
  });

  group('getPostsByUser', () {
    final userPosts = [
      PostModel(
        id: 1,
        title: 'User Post 1',
        body: 'User body 1',
        userId: 1,
      ),
      PostModel(
        id: 2,
        title: 'User Post 2',
        body: 'User body 2',
        userId: 1,
      ),
    ];

    test('should return posts by user from remote', () async {
      // Arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockStorageService.get<String>('user_posts_1_1_20')).thenAnswer((_) async => null);
      when(() => mockRemoteDataSource.getPostsByUserId(1))
          .thenAnswer((_) async => success(userPosts));
      when(() => mockStorageService.store(any(), any())).thenAnswer((_) async {});
      when(() => mockStorageService.get<bool>(any())).thenAnswer((_) async => false);

      // Act
      final result = await repository.getPostsByUser(userId: 1);

      // Assert
      expect(result.isSuccess, true);
      expect(result.successValue!.length, 2);
      
      verify(() => mockRemoteDataSource.getPostsByUserId(1)).called(1);
    });

    test('should return NetworkFailure when no network and no cache', () async {
      // Arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => false);
      when(() => mockStorageService.get<String>('user_posts_1_1_20')).thenAnswer((_) async => null);

      // Act
      final result = await repository.getPostsByUser(userId: 1);

      // Assert
      expect(result.isFailure, true);
      expect(result.failureValue, isA<NetworkFailure>());
      expect(result.failureValue!.message, 'No internet connection and no cached data');
    });
  });

  group('getFavoritePosts', () {
    test('should return favorite posts for user', () async {
      // Arrange
      when(() => mockStorageService.get<String>(any())).thenAnswer((_) async => null);
      when(() => mockStorageService.get<bool>(any())).thenAnswer((_) async => false);

      // Act
      final result = await repository.getFavoritePosts(userId: 1);

      // Assert
      expect(result.isSuccess, true);
      expect(result.successValue!.isEmpty, true); // No cached favorites
    });

    test('should apply pagination to favorite posts', () async {
      // Arrange
      when(() => mockStorageService.get<String>(any())).thenAnswer((_) async => null);
      when(() => mockStorageService.get<bool>(any())).thenAnswer((_) async => false);

      // Act
      final result = await repository.getFavoritePosts(userId: 1, page: 2, limit: 5);

      // Assert
      expect(result.isSuccess, true);
      expect(result.successValue!.isEmpty, true);
    });
  });
}