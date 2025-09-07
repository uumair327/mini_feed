import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mini_feed/core/network/network_client.dart';
import 'package:mini_feed/core/errors/exceptions.dart';
import 'package:mini_feed/core/utils/result.dart';
import 'package:mini_feed/data/datasources/remote/post_remote_datasource.dart';
import 'package:mini_feed/data/models/post_model.dart';
import 'package:mini_feed/data/models/comment_model.dart';

class MockNetworkClient extends Mock implements NetworkClient {}

void main() {
  group('PostRemoteDataSourceImpl', () {
    late PostRemoteDataSourceImpl dataSource;
    late MockNetworkClient mockNetworkClient;

    setUp(() {
      mockNetworkClient = MockNetworkClient();
      dataSource = PostRemoteDataSourceImpl(mockNetworkClient);
    });

    group('getPosts', () {
      test('should return list of PostModel when request is successful', () async {
        // Arrange
        final response = Response(
          data: [
            {
              'userId': 1,
              'id': 1,
              'title': 'Test Post 1',
              'body': 'Test body 1',
            },
            {
              'userId': 1,
              'id': 2,
              'title': 'Test Post 2',
              'body': 'Test body 2',
            },
          ],
          statusCode: 200,
          requestOptions: RequestOptions(path: '/posts'),
        );

        when(() => mockNetworkClient.get(
          '/posts',
          queryParameters: any(named: 'queryParameters'),
        )).thenAnswer((_) async => response);

        // Act
        final result = await dataSource.getPosts(page: 1, limit: 20);

        // Assert
        expect(result.isSuccess, isTrue);
        final posts = result.successValue!;
        expect(posts, hasLength(2));
        expect(posts[0].id, equals(1));
        expect(posts[0].title, equals('Test Post 1'));
        expect(posts[1].id, equals(2));
        expect(posts[1].title, equals('Test Post 2'));

        verify(() => mockNetworkClient.get(
          '/posts',
          queryParameters: {'_page': 1, '_limit': 20},
        )).called(1);
      });

      test('should throw ServerException when request fails', () async {
        // Arrange
        when(() => mockNetworkClient.get(
          '/posts',
          queryParameters: any(named: 'queryParameters'),
        )).thenThrow(DioException(
          response: Response(
            statusCode: 500,
            requestOptions: RequestOptions(path: '/posts'),
          ),
          requestOptions: RequestOptions(path: '/posts'),
        ));

        // Act & Assert
        expect(
          () => dataSource.getPosts(),
          throwsA(isA<ServerException>()),
        );
      });
    });

    group('getPostById', () {
      const postId = 1;

      test('should return PostModel when request is successful', () async {
        // Arrange
        final response = Response(
          data: {
            'userId': 1,
            'id': 1,
            'title': 'Test Post',
            'body': 'Test body',
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/posts/1'),
        );

        when(() => mockNetworkClient.get('/posts/$postId'))
            .thenAnswer((_) async => response);

        // Act
        final result = await dataSource.getPostById(postId);

        // Assert
        expect(result.isSuccess, isTrue);
        final post = result.successValue;
        expect(post.id, equals(1));
        expect(post.title, equals('Test Post'));
        expect(post.body, equals('Test body'));
        expect(post.userId, equals(1));

        verify(() => mockNetworkClient.get('/posts/$postId')).called(1);
      });

      test('should throw ServerException when post not found', () async {
        // Arrange
        when(() => mockNetworkClient.get('/posts/$postId'))
            .thenThrow(DioException(
          response: Response(
            statusCode: 404,
            requestOptions: RequestOptions(path: '/posts/$postId'),
          ),
          requestOptions: RequestOptions(path: '/posts/$postId'),
        ));

        // Act & Assert
        expect(
          () => dataSource.getPostById(postId),
          throwsA(isA<ServerException>().having(
            (e) => e.message,
            'message',
            'Post not found',
          )),
        );
      });
    });

    group('getPostsByUserId', () {
      const userId = 1;

      test('should return list of PostModel for specific user', () async {
        // Arrange
        final response = Response(
          data: [
            {
              'userId': 1,
              'id': 1,
              'title': 'User Post 1',
              'body': 'User body 1',
            },
            {
              'userId': 1,
              'id': 2,
              'title': 'User Post 2',
              'body': 'User body 2',
            },
          ],
          statusCode: 200,
          requestOptions: RequestOptions(path: '/posts'),
        );

        when(() => mockNetworkClient.get(
          '/posts',
          queryParameters: any(named: 'queryParameters'),
        )).thenAnswer((_) async => response);

        // Act
        final result = await dataSource.getPostsByUserId(userId);

        // Assert
        expect(result.isSuccess, isTrue);
        final posts = result.successValue;
        expect(posts, hasLength(2));
        expect(posts.every((post) => post.userId == userId), isTrue);

        verify(() => mockNetworkClient.get(
          '/posts',
          queryParameters: {'userId': userId},
        )).called(1);
      });
    });

    group('createPost', () {
      const title = 'New Post';
      const body = 'New post body';
      const userId = 1;

      test('should return PostModel when post is created successfully', () async {
        // Arrange
        final response = Response(
          data: {
            'userId': userId,
            'id': 101,
            'title': title,
            'body': body,
          },
          statusCode: 201,
          requestOptions: RequestOptions(path: '/posts'),
        );

        when(() => mockNetworkClient.post(
          '/posts',
          data: any(named: 'data'),
        )).thenAnswer((_) async => response);

        // Act
        final result = await dataSource.createPost(
          title: title,
          body: body,
          userId: userId,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        final post = result.successValue;
        expect(post.id, equals(101));
        expect(post.title, equals(title));
        expect(post.body, equals(body));
        expect(post.userId, equals(userId));

        verify(() => mockNetworkClient.post(
          '/posts',
          data: {
            'title': title,
            'body': body,
            'userId': userId,
          },
        )).called(1);
      });

      test('should throw ServerException when post data is invalid', () async {
        // Arrange
        when(() => mockNetworkClient.post(
          '/posts',
          data: any(named: 'data'),
        )).thenThrow(DioException(
          response: Response(
            statusCode: 400,
            requestOptions: RequestOptions(path: '/posts'),
          ),
          requestOptions: RequestOptions(path: '/posts'),
        ));

        // Act & Assert
        expect(
          () => dataSource.createPost(title: '', body: body, userId: userId),
          throwsA(isA<ServerException>().having(
            (e) => e.message,
            'message',
            'Invalid post data',
          )),
        );
      });
    });

    group('updatePost', () {
      const postId = 1;
      const newTitle = 'Updated Title';
      const newBody = 'Updated body';

      test('should return updated PostModel when update is successful', () async {
        // Arrange
        final response = Response(
          data: {
            'userId': 1,
            'id': postId,
            'title': newTitle,
            'body': newBody,
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/posts/$postId'),
        );

        when(() => mockNetworkClient.patch(
          '/posts/$postId',
          data: any(named: 'data'),
        )).thenAnswer((_) async => response);

        // Act
        final result = await dataSource.updatePost(
          postId: postId,
          title: newTitle,
          body: newBody,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        final post = result.successValue;
        expect(post.id, equals(postId));
        expect(post.title, equals(newTitle));
        expect(post.body, equals(newBody));

        verify(() => mockNetworkClient.patch(
          '/posts/$postId',
          data: {'title': newTitle, 'body': newBody},
        )).called(1);
      });

      test('should throw ServerException when post not found', () async {
        // Arrange
        when(() => mockNetworkClient.patch(
          '/posts/$postId',
          data: any(named: 'data'),
        )).thenThrow(DioException(
          response: Response(
            statusCode: 404,
            requestOptions: RequestOptions(path: '/posts/$postId'),
          ),
          requestOptions: RequestOptions(path: '/posts/$postId'),
        ));

        // Act & Assert
        expect(
          () => dataSource.updatePost(postId: postId, title: newTitle),
          throwsA(isA<ServerException>().having(
            (e) => e.message,
            'message',
            'Post not found',
          )),
        );
      });
    });

    group('deletePost', () {
      const postId = 1;

      test('should complete successfully when post is deleted', () async {
        // Arrange
        final response = Response(
          statusCode: 200,
          requestOptions: RequestOptions(path: '/posts/$postId'),
        );

        when(() => mockNetworkClient.delete('/posts/$postId'))
            .thenAnswer((_) async => response);

        // Act
        final result = await dataSource.deletePost(postId);

        // Assert
        expect(result.isSuccess, isTrue);
        verify(() => mockNetworkClient.delete('/posts/$postId')).called(1);
      });

      test('should throw ServerException when post not found', () async {
        // Arrange
        when(() => mockNetworkClient.delete('/posts/$postId'))
            .thenThrow(DioException(
          response: Response(
            statusCode: 404,
            requestOptions: RequestOptions(path: '/posts/$postId'),
          ),
          requestOptions: RequestOptions(path: '/posts/$postId'),
        ));

        // Act & Assert
        expect(
          () => dataSource.deletePost(postId),
          throwsA(isA<ServerException>().having(
            (e) => e.message,
            'message',
            'Post not found',
          )),
        );
      });
    });

    group('getComments', () {
      const postId = 1;

      test('should return list of CommentModel when request is successful', () async {
        // Arrange
        final response = Response(
          data: [
            {
              'postId': 1,
              'id': 1,
              'name': 'Test Commenter',
              'email': 'test@example.com',
              'body': 'Test comment',
            },
            {
              'postId': 1,
              'id': 2,
              'name': 'Another Commenter',
              'email': 'another@example.com',
              'body': 'Another comment',
            },
          ],
          statusCode: 200,
          requestOptions: RequestOptions(path: '/posts/$postId/comments'),
        );

        when(() => mockNetworkClient.get(
          '/posts/$postId/comments',
          queryParameters: any(named: 'queryParameters'),
        )).thenAnswer((_) async => response);

        // Act
        final result = await dataSource.getComments(postId: postId);

        // Assert
        expect(result.isSuccess, isTrue);
        final comments = result.successValue;
        expect(comments, hasLength(2));
        expect(comments[0].id, equals(1));
        expect(comments[0].name, equals('Test Commenter'));
        expect(comments[1].id, equals(2));
        expect(comments[1].name, equals('Another Commenter'));

        verify(() => mockNetworkClient.get(
          '/posts/$postId/comments',
          queryParameters: {'_page': 1, '_limit': 20},
        )).called(1);
      });

      test('should throw ServerException when post not found', () async {
        // Arrange
        when(() => mockNetworkClient.get(
          '/posts/$postId/comments',
          queryParameters: any(named: 'queryParameters'),
        )).thenThrow(DioException(
          response: Response(
            statusCode: 404,
            requestOptions: RequestOptions(path: '/posts/$postId/comments'),
          ),
          requestOptions: RequestOptions(path: '/posts/$postId/comments'),
        ));

        // Act & Assert
        expect(
          () => dataSource.getComments(postId: postId),
          throwsA(isA<ServerException>().having(
            (e) => e.message,
            'message',
            'Post not found',
          )),
        );
      });
    });

    group('createComment', () {
      const postId = 1;
      const name = 'Test Commenter';
      const email = 'test@example.com';
      const body = 'Test comment body';

      test('should return CommentModel when comment is created successfully', () async {
        // Arrange
        final response = Response(
          data: {
            'postId': postId,
            'id': 501,
            'name': name,
            'email': email,
            'body': body,
          },
          statusCode: 201,
          requestOptions: RequestOptions(path: '/comments'),
        );

        when(() => mockNetworkClient.post(
          '/comments',
          data: any(named: 'data'),
        )).thenAnswer((_) async => response);

        // Act
        final result = await dataSource.createComment(
          postId: postId,
          name: name,
          email: email,
          body: body,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        final comment = result.successValue;
        expect(comment.id, equals(501));
        expect(comment.postId, equals(postId));
        expect(comment.name, equals(name));
        expect(comment.email, equals(email));
        expect(comment.body, equals(body));

        verify(() => mockNetworkClient.post(
          '/comments',
          data: {
            'postId': postId,
            'name': name,
            'email': email,
            'body': body,
          },
        )).called(1);
      });

      test('should throw ServerException when comment data is invalid', () async {
        // Arrange
        when(() => mockNetworkClient.post(
          '/comments',
          data: any(named: 'data'),
        )).thenThrow(DioException(
          response: Response(
            statusCode: 400,
            requestOptions: RequestOptions(path: '/comments'),
          ),
          requestOptions: RequestOptions(path: '/comments'),
        ));

        // Act & Assert
        expect(
          () => dataSource.createComment(
            postId: postId,
            name: '',
            email: email,
            body: body,
          ),
          throwsA(isA<ServerException>().having(
            (e) => e.message,
            'message',
            'Invalid comment data',
          )),
        );
      });
    });

    group('searchPosts', () {
      const query = 'test';

      test('should return filtered posts when search is successful', () async {
        // Arrange
        final response = Response(
          data: [
            {
              'userId': 1,
              'id': 1,
              'title': 'Test Post',
              'body': 'This is a test post',
            },
            {
              'userId': 1,
              'id': 2,
              'title': 'Another Post',
              'body': 'This post does not match',
            },
            {
              'userId': 1,
              'id': 3,
              'title': 'Testing Again',
              'body': 'Another test post',
            },
          ],
          statusCode: 200,
          requestOptions: RequestOptions(path: '/posts'),
        );

        when(() => mockNetworkClient.get(
          '/posts',
          queryParameters: any(named: 'queryParameters'),
        )).thenAnswer((_) async => response);

        // Act
        final result = await dataSource.searchPosts(query: query);

        // Assert
        expect(result.isSuccess, isTrue);
        final posts = result.successValue;
        expect(posts, hasLength(2)); // Only posts with 'test' in title or body
        expect(posts[0].title, contains('Test'));
        expect(posts[1].title, contains('Testing'));

        verify(() => mockNetworkClient.get(
          '/posts',
          queryParameters: {'_page': 1, '_limit': 100},
        )).called(1);
      });

      test('should return empty list when no posts match query', () async {
        // Arrange
        final response = Response(
          data: [
            {
              'userId': 1,
              'id': 1,
              'title': 'Random Post',
              'body': 'Random content',
            },
          ],
          statusCode: 200,
          requestOptions: RequestOptions(path: '/posts'),
        );

        when(() => mockNetworkClient.get(
          '/posts',
          queryParameters: any(named: 'queryParameters'),
        )).thenAnswer((_) async => response);

        // Act
        final result = await dataSource.searchPosts(query: 'nonexistent');

        // Assert
        expect(result.isSuccess, isTrue);
        final posts = result.successValue;
        expect(posts, isEmpty);
      });

      test('should handle pagination correctly', () async {
        // Arrange
        final posts = List.generate(10, (index) => {
          'userId': 1,
          'id': index + 1,
          'title': 'Test Post ${index + 1}',
          'body': 'Test body ${index + 1}',
        });

        final response = Response(
          data: posts,
          statusCode: 200,
          requestOptions: RequestOptions(path: '/posts'),
        );

        when(() => mockNetworkClient.get(
          '/posts',
          queryParameters: any(named: 'queryParameters'),
        )).thenAnswer((_) async => response);

        // Act
        final result = await dataSource.searchPosts(
          query: 'test',
          page: 2,
          limit: 3,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        final resultPosts = result.successValue;
        expect(resultPosts, hasLength(3)); // Second page with 3 items
        expect(resultPosts[0].title, equals('Test Post 4')); // Starting from 4th item
      });
    });

    group('error handling', () {
      test('should handle unexpected exceptions', () async {
        // Arrange
        when(() => mockNetworkClient.get(
          '/posts',
          queryParameters: any(named: 'queryParameters'),
        )).thenThrow(Exception('Unexpected error'));

        // Act & Assert
        expect(
          () => dataSource.getPosts(),
          throwsA(isA<ServerException>().having(
            (e) => e.message,
            'message',
            contains('Unexpected error getting posts'),
          )),
        );
      });

      test('should handle different HTTP status codes', () async {
        // Arrange
        when(() => mockNetworkClient.get('/posts/1'))
            .thenThrow(DioException(
          response: Response(
            statusCode: 403,
            requestOptions: RequestOptions(path: '/posts/1'),
          ),
          requestOptions: RequestOptions(path: '/posts/1'),
        ));

        // Act & Assert
        expect(
          () => dataSource.getPostById(1),
          throwsA(isA<ServerException>().having(
            (e) => e.statusCode,
            'statusCode',
            403,
          )),
        );
      });
    });
  });
}