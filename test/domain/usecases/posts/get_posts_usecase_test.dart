import 'package:flutter_test/flutter_test.dart';
import 'package:mini_feed/core/errors/failures.dart';
import 'package:mini_feed/core/utils/result.dart';
import 'package:mini_feed/domain/entities/post.dart';
import 'package:mini_feed/domain/repositories/post_repository.dart';
import 'package:mini_feed/domain/usecases/posts/get_posts_usecase.dart';

// Mock implementation for testing
class MockPostRepository implements PostRepository {
  bool shouldSucceed = true;
  List<Post> mockPosts = const [
    Post(id: 1, title: 'Post 1', body: 'Body 1', userId: 1),
    Post(id: 2, title: 'Post 2', body: 'Body 2', userId: 2),
  ];

  @override
  Future<Result<List<Post>, Failure>> getPosts({
    int? page,
    int? limit,
    bool forceRefresh = false,
  }) async {
    if (!shouldSucceed) {
      return Result.failure(const ServerFailure('Failed to fetch posts'));
    }
    return Result.success(mockPosts);
  }

  // Other methods not needed for this test
  @override
  Future<Result<Post, Failure>> getPost({
    required int id,
    bool forceRefresh = false,
  }) async => throw UnimplementedError();

  @override
  Future<Result<List<Post>, Failure>> getPostsByUser({
    required int userId,
    int? page,
    int? limit,
    bool forceRefresh = false,
  }) async => throw UnimplementedError();

  @override
  Future<Result<Post, Failure>> createPost({
    required String title,
    required String body,
  }) async => throw UnimplementedError();

  @override
  Future<Result<Post, Failure>> updatePost({
    required int id,
    String? title,
    String? body,
  }) async => throw UnimplementedError();

  @override
  Future<Result<void, Failure>> deletePost({
    required int id,
  }) async => throw UnimplementedError();

  @override
  Future<Result<Post, Failure>> toggleFavorite({
    required int id,
  }) async => throw UnimplementedError();

  @override
  Future<Result<List<Post>, Failure>> getFavoritePosts({
    int? page,
    int? limit,
    bool forceRefresh = false,
  }) async => throw UnimplementedError();

  @override
  Future<Result<List<Post>, Failure>> searchPosts({
    required String query,
    int? page,
    int? limit,
  }) async => throw UnimplementedError();

  @override
  Future<Result<List<Post>, Failure>> getCachedPosts() async => throw UnimplementedError();

  @override
  Future<Result<void, Failure>> syncPosts() async => throw UnimplementedError();

  @override
  Future<Result<void, Failure>> clearCache() async => throw UnimplementedError();

  @override
  Future<Result<int, Failure>> getPostsCount() async => throw UnimplementedError();

  @override
  Future<bool> hasMorePosts() async => throw UnimplementedError();

  @override
  Future<Result<List<Post>, Failure>> refreshPosts() async => throw UnimplementedError();
}

void main() {
  group('GetPostsUseCase', () {
    late GetPostsUseCase useCase;
    late MockPostRepository mockRepository;

    setUp(() {
      mockRepository = MockPostRepository();
      useCase = GetPostsUseCase(mockRepository);
    });

    group('successful execution', () {
      test('should return posts when repository succeeds', () async {
        // Arrange
        mockRepository.shouldSucceed = true;
        const params = GetPostsParams();

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isA<List<Post>>());
        expect(result.data?.length, equals(2));
      });

      test('should pass parameters correctly to repository', () async {
        // Arrange
        int? capturedPage;
        int? capturedLimit;
        bool? capturedForceRefresh;
        
        final originalGetPosts = mockRepository.getPosts;
        mockRepository.getPosts = ({int? page, int? limit, bool forceRefresh = false}) async {
          capturedPage = page;
          capturedLimit = limit;
          capturedForceRefresh = forceRefresh;
          return originalGetPosts(page: page, limit: limit, forceRefresh: forceRefresh);
        };

        const params = GetPostsParams(
          page: 2,
          limit: 10,
          forceRefresh: true,
        );

        // Act
        await useCase(params);

        // Assert
        expect(capturedPage, equals(2));
        expect(capturedLimit, equals(10));
        expect(capturedForceRefresh, equals(true));
      });
    });

    group('validation errors', () {
      test('should return ValidationFailure when page is less than 1', () async {
        // Arrange
        const params = GetPostsParams(page: 0);

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.error, isA<ValidationFailure>());
        expect(result.error?.message, equals('Page number must be greater than 0'));
      });

      test('should return ValidationFailure when limit is less than 1', () async {
        // Arrange
        const params = GetPostsParams(limit: 0);

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.error, isA<ValidationFailure>());
        expect(result.error?.message, equals('Limit must be greater than 0'));
      });

      test('should return ValidationFailure when limit exceeds 100', () async {
        // Arrange
        const params = GetPostsParams(limit: 101);

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.error, isA<ValidationFailure>());
        expect(result.error?.message, equals('Limit cannot exceed 100 posts'));
      });
    });

    group('repository errors', () {
      test('should return failure when repository fails', () async {
        // Arrange
        mockRepository.shouldSucceed = false;
        const params = GetPostsParams();

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.error, isA<ServerFailure>());
      });
    });

    group('valid parameters', () {
      test('should accept valid page numbers', () async {
        // Arrange
        mockRepository.shouldSucceed = true;
        const validPages = [1, 5, 10, 100];

        for (final page in validPages) {
          final params = GetPostsParams(page: page);

          // Act
          final result = await useCase(params);

          // Assert
          expect(result.isSuccess, isTrue, reason: 'Failed for page: $page');
        }
      });

      test('should accept valid limits', () async {
        // Arrange
        mockRepository.shouldSucceed = true;
        const validLimits = [1, 10, 20, 50, 100];

        for (final limit in validLimits) {
          final params = GetPostsParams(limit: limit);

          // Act
          final result = await useCase(params);

          // Assert
          expect(result.isSuccess, isTrue, reason: 'Failed for limit: $limit');
        }
      });

      test('should accept null parameters', () async {
        // Arrange
        mockRepository.shouldSucceed = true;
        const params = GetPostsParams(
          page: null,
          limit: null,
          forceRefresh: false,
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isSuccess, isTrue);
      });
    });
  });

  group('GetPostsParams', () {
    test('should have correct equality and hashCode', () {
      // Arrange
      const params1 = GetPostsParams(page: 1, limit: 10, forceRefresh: true);
      const params2 = GetPostsParams(page: 1, limit: 10, forceRefresh: true);
      const params3 = GetPostsParams(page: 2, limit: 10, forceRefresh: true);

      // Assert
      expect(params1, equals(params2));
      expect(params1.hashCode, equals(params2.hashCode));
      expect(params1, isNot(equals(params3)));
      expect(params1.hashCode, isNot(equals(params3.hashCode)));
    });

    test('should have correct toString', () {
      // Arrange
      const params = GetPostsParams(page: 1, limit: 10, forceRefresh: true);

      // Act
      final string = params.toString();

      // Assert
      expect(string, contains('page: 1'));
      expect(string, contains('limit: 10'));
      expect(string, contains('forceRefresh: true'));
    });
  });
}