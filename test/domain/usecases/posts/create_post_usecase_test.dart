import 'package:flutter_test/flutter_test.dart';
import 'package:mini_feed/core/errors/failures.dart';
import 'package:mini_feed/core/utils/result.dart';
import 'package:mini_feed/domain/entities/post.dart';
import 'package:mini_feed/domain/repositories/post_repository.dart';
import 'package:mini_feed/domain/usecases/posts/create_post_usecase.dart';

// Mock implementation for testing
class MockPostRepository implements PostRepository {
  bool shouldSucceed = true;
  String? capturedTitle;
  String? capturedBody;

  @override
  Future<Result<Post, Failure>> createPost({
    required String title,
    required String body,
  }) async {
    capturedTitle = title;
    capturedBody = body;
    
    if (!shouldSucceed) {
      return Result.failure(const ServerFailure('Failed to create post'));
    }
    
    return Result.success(Post(
      id: 1,
      title: title,
      body: body,
      userId: 1,
    ));
  }

  // Other methods not needed for this test
  @override
  Future<Result<List<Post>, Failure>> getPosts({
    int? page,
    int? limit,
    bool forceRefresh = false,
  }) async => throw UnimplementedError();

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
  group('CreatePostUseCase', () {
    late CreatePostUseCase useCase;
    late MockPostRepository mockRepository;

    setUp(() {
      mockRepository = MockPostRepository();
      useCase = CreatePostUseCase(mockRepository);
    });

    group('successful creation', () {
      test('should return Post when creation is successful', () async {
        // Arrange
        mockRepository.shouldSucceed = true;
        const params = CreatePostParams(
          title: 'Test Post Title',
          body: 'This is a test post body with enough content.',
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.data, isA<Post>());
        expect(result.data?.title, equals('Test Post Title'));
        expect(result.data?.body, equals('This is a test post body with enough content.'));
      });

      test('should trim whitespace from title and body', () async {
        // Arrange
        mockRepository.shouldSucceed = true;
        const params = CreatePostParams(
          title: '  Test Post Title  ',
          body: '  This is a test post body with enough content.  ',
        );

        // Act
        await useCase(params);

        // Assert
        expect(mockRepository.capturedTitle, equals('Test Post Title'));
        expect(mockRepository.capturedBody, equals('This is a test post body with enough content.'));
      });
    });

    group('validation errors', () {
      test('should return ValidationFailure when title is empty', () async {
        // Arrange
        const params = CreatePostParams(
          title: '',
          body: 'This is a test post body with enough content.',
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.error, isA<ValidationFailure>());
        expect(result.error?.message, equals('Post title is required'));
      });

      test('should return ValidationFailure when title is only whitespace', () async {
        // Arrange
        const params = CreatePostParams(
          title: '   ',
          body: 'This is a test post body with enough content.',
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.error, isA<ValidationFailure>());
        expect(result.error?.message, equals('Post title is required'));
      });

      test('should return ValidationFailure when body is empty', () async {
        // Arrange
        const params = CreatePostParams(
          title: 'Test Post Title',
          body: '',
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.error, isA<ValidationFailure>());
        expect(result.error?.message, equals('Post content is required'));
      });

      test('should return ValidationFailure when body is only whitespace', () async {
        // Arrange
        const params = CreatePostParams(
          title: 'Test Post Title',
          body: '   ',
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.error, isA<ValidationFailure>());
        expect(result.error?.message, equals('Post content is required'));
      });

      test('should return ValidationFailure when title is too short', () async {
        // Arrange
        const params = CreatePostParams(
          title: 'Hi',
          body: 'This is a test post body with enough content.',
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.error, isA<ValidationFailure>());
        expect(result.error?.message, equals('Post title must be at least 3 characters'));
      });

      test('should return ValidationFailure when body is too short', () async {
        // Arrange
        const params = CreatePostParams(
          title: 'Test Post Title',
          body: 'Short',
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.error, isA<ValidationFailure>());
        expect(result.error?.message, equals('Post content must be at least 10 characters'));
      });

      test('should return ValidationFailure when title is too long', () async {
        // Arrange
        final longTitle = 'A' * 201; // 201 characters
        const params = CreatePostParams(
          title: longTitle,
          body: 'This is a test post body with enough content.',
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.error, isA<ValidationFailure>());
        expect(result.error?.message, equals('Post title cannot exceed 200 characters'));
      });

      test('should return ValidationFailure when body is too long', () async {
        // Arrange
        final longBody = 'A' * 5001; // 5001 characters
        const params = CreatePostParams(
          title: 'Test Post Title',
          body: longBody,
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.error, isA<ValidationFailure>());
        expect(result.error?.message, equals('Post content cannot exceed 5000 characters'));
      });
    });

    group('repository errors', () {
      test('should return failure when repository fails', () async {
        // Arrange
        mockRepository.shouldSucceed = false;
        const params = CreatePostParams(
          title: 'Test Post Title',
          body: 'This is a test post body with enough content.',
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isFailure, isTrue);
        expect(result.error, isA<ServerFailure>());
      });
    });

    group('valid inputs', () {
      test('should accept minimum valid lengths', () async {
        // Arrange
        mockRepository.shouldSucceed = true;
        const params = CreatePostParams(
          title: 'ABC', // 3 characters (minimum)
          body: '1234567890', // 10 characters (minimum)
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isSuccess, isTrue);
      });

      test('should accept maximum valid lengths', () async {
        // Arrange
        mockRepository.shouldSucceed = true;
        final maxTitle = 'A' * 200; // 200 characters (maximum)
        final maxBody = 'B' * 5000; // 5000 characters (maximum)
        final params = CreatePostParams(
          title: maxTitle,
          body: maxBody,
        );

        // Act
        final result = await useCase(params);

        // Assert
        expect(result.isSuccess, isTrue);
      });
    });
  });

  group('CreatePostParams', () {
    test('should have correct equality and hashCode', () {
      // Arrange
      const params1 = CreatePostParams(title: 'Title', body: 'Body content here');
      const params2 = CreatePostParams(title: 'Title', body: 'Body content here');
      const params3 = CreatePostParams(title: 'Different', body: 'Body content here');

      // Assert
      expect(params1, equals(params2));
      expect(params1.hashCode, equals(params2.hashCode));
      expect(params1, isNot(equals(params3)));
      expect(params1.hashCode, isNot(equals(params3.hashCode)));
    });

    test('should show character count in toString', () {
      // Arrange
      const params = CreatePostParams(
        title: 'Test Title',
        body: 'This is a test body with some content',
      );

      // Act
      final string = params.toString();

      // Assert
      expect(string, contains('Test Title'));
      expect(string, contains('37 chars')); // Length of the body
    });
  });
}