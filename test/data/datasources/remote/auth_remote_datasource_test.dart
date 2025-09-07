import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mini_feed/core/network/network_client.dart';
import 'package:mini_feed/core/errors/exceptions.dart';
import 'package:mini_feed/core/utils/result.dart';
import 'package:mini_feed/data/datasources/remote/auth_remote_datasource.dart';
import 'package:mini_feed/data/models/login_response_model.dart';
import 'package:mini_feed/data/models/user_model.dart';

class MockNetworkClient extends Mock implements NetworkClient {}

void main() {
  group('AuthRemoteDataSourceImpl', () {
    late AuthRemoteDataSourceImpl dataSource;
    late MockNetworkClient mockNetworkClient;

    setUp(() {
      mockNetworkClient = MockNetworkClient();
      dataSource = AuthRemoteDataSourceImpl(mockNetworkClient);
    });

    group('login', () {
      const email = 'eve.holt@reqres.in';
      const password = 'cityslicka';
      const token = 'QpwL5tke4Pnpja7X4';

      test('should return LoginResponseModel when login is successful', () async {
        // Arrange
        final loginResponse = Response(
          data: {'token': token},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/login'),
        );

        final userResponse = Response(
          data: {
            'data': {
              'id': 4,
              'email': 'eve.holt@reqres.in',
              'first_name': 'Eve',
              'last_name': 'Holt',
              'avatar': 'https://reqres.in/img/faces/4-image.jpg',
            }
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/users/4'),
        );

        when(() => mockNetworkClient.post(
          '/login',
          data: any(named: 'data'),
        )).thenAnswer((_) async => loginResponse);

        when(() => mockNetworkClient.get('/users/4'))
            .thenAnswer((_) async => userResponse);

        // Act
        final result = await dataSource.login(email: email, password: password);

        // Assert
        expect(result.isSuccess, isTrue);
        final loginResponseModel = result.successValue!;
        expect(loginResponseModel.token, equals(token));
        expect(loginResponseModel.user.email, equals(email));
        expect(loginResponseModel.user.firstName, equals('Eve'));
        expect(loginResponseModel.user.lastName, equals('Holt'));
        expect(loginResponseModel.tokenType, equals('Bearer'));
        expect(loginResponseModel.expiresIn, equals(3600));

        verify(() => mockNetworkClient.post(
          '/login',
          data: {'email': email, 'password': password},
        )).called(1);
        verify(() => mockNetworkClient.get('/users/4')).called(1);
      });

      test('should throw ServerException when credentials are invalid', () async {
        // Arrange
        when(() => mockNetworkClient.post(
          '/login',
          data: any(named: 'data'),
        )).thenThrow(DioException(
          response: Response(
            statusCode: 400,
            requestOptions: RequestOptions(path: '/login'),
          ),
          requestOptions: RequestOptions(path: '/login'),
        ));

        // Act & Assert
        expect(
          () => dataSource.login(email: email, password: 'wrong'),
          throwsA(isA<ServerException>().having(
            (e) => e.message,
            'message',
            'Invalid credentials',
          )),
        );
      });

      test('should throw ServerException when user not found', () async {
        // Arrange
        when(() => mockNetworkClient.post(
          '/login',
          data: any(named: 'data'),
        )).thenThrow(DioException(
          response: Response(
            statusCode: 404,
            requestOptions: RequestOptions(path: '/login'),
          ),
          requestOptions: RequestOptions(path: '/login'),
        ));

        // Act & Assert
        expect(
          () => dataSource.login(email: 'nonexistent@test.com', password: password),
          throwsA(isA<ServerException>().having(
            (e) => e.message,
            'message',
            'User not found',
          )),
        );
      });

      test('should throw ServerException for other HTTP errors', () async {
        // Arrange
        when(() => mockNetworkClient.post(
          '/login',
          data: any(named: 'data'),
        )).thenThrow(DioException(
          response: Response(
            statusCode: 500,
            requestOptions: RequestOptions(path: '/login'),
          ),
          requestOptions: RequestOptions(path: '/login'),
          message: 'Internal server error',
        ));

        // Act & Assert
        expect(
          () => dataSource.login(email: email, password: password),
          throwsA(isA<ServerException>().having(
            (e) => e.message,
            'message',
            contains('Login failed'),
          )),
        );
      });

      test('should handle different email mappings', () async {
        // Arrange
        const testEmail = 'janet.weaver@reqres.in';
        final loginResponse = Response(
          data: {'token': token},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/login'),
        );

        final userResponse = Response(
          data: {
            'data': {
              'id': 2,
              'email': 'janet.weaver@reqres.in',
              'first_name': 'Janet',
              'last_name': 'Weaver',
              'avatar': 'https://reqres.in/img/faces/2-image.jpg',
            }
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/users/2'),
        );

        when(() => mockNetworkClient.post(
          '/login',
          data: any(named: 'data'),
        )).thenAnswer((_) async => loginResponse);

        when(() => mockNetworkClient.get('/users/2'))
            .thenAnswer((_) async => userResponse);

        // Act
        final result = await dataSource.login(email: testEmail, password: password);

        // Assert
        expect(result.isSuccess, isTrue);
        expect(result.successValue!.user.firstName, equals('Janet'));
        verify(() => mockNetworkClient.get('/users/2')).called(1);
      });
    });

    group('getUserProfile', () {
      const userId = 1;

      test('should return UserModel when request is successful', () async {
        // Arrange
        final response = Response(
          data: {
            'data': {
              'id': 1,
              'email': 'george.bluth@reqres.in',
              'first_name': 'George',
              'last_name': 'Bluth',
              'avatar': 'https://reqres.in/img/faces/1-image.jpg',
            }
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/users/1'),
        );

        when(() => mockNetworkClient.get('/users/$userId'))
            .thenAnswer((_) async => response);

        // Act
        final result = await dataSource.getUserProfile(userId);

        // Assert
        expect(result.isSuccess, isTrue);
        final user = result.successValue!;
        expect(user.id, equals(1));
        expect(user.email, equals('george.bluth@reqres.in'));
        expect(user.firstName, equals('George'));
        expect(user.lastName, equals('Bluth'));

        verify(() => mockNetworkClient.get('/users/$userId')).called(1);
      });

      test('should throw ServerException when user not found', () async {
        // Arrange
        when(() => mockNetworkClient.get('/users/$userId'))
            .thenThrow(DioException(
          response: Response(
            statusCode: 404,
            requestOptions: RequestOptions(path: '/users/$userId'),
          ),
          requestOptions: RequestOptions(path: '/users/$userId'),
        ));

        // Act & Assert
        expect(
          () => dataSource.getUserProfile(userId),
          throwsA(isA<ServerException>().having(
            (e) => e.message,
            'message',
            'User not found',
          )),
        );
      });

      test('should throw ServerException for other HTTP errors', () async {
        // Arrange
        when(() => mockNetworkClient.get('/users/$userId'))
            .thenThrow(DioException(
          response: Response(
            statusCode: 500,
            requestOptions: RequestOptions(path: '/users/$userId'),
          ),
          requestOptions: RequestOptions(path: '/users/$userId'),
          message: 'Server error',
        ));

        // Act & Assert
        expect(
          () => dataSource.getUserProfile(userId),
          throwsA(isA<ServerException>().having(
            (e) => e.message,
            'message',
            contains('Failed to get user profile'),
          )),
        );
      });
    });

    group('register', () {
      const email = 'eve.holt@reqres.in';
      const password = 'pistol';
      const firstName = 'Eve';
      const lastName = 'Holt';

      test('should return LoginResponseModel when registration is successful', () async {
        // Arrange
        final response = Response(
          data: {
            'id': 4,
            'token': 'QpwL5tke4Pnpja7X4',
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/register'),
        );

        when(() => mockNetworkClient.post(
          '/register',
          data: any(named: 'data'),
        )).thenAnswer((_) async => response);

        // Act
        final result = await dataSource.register(
          email: email,
          password: password,
          firstName: firstName,
          lastName: lastName,
        );

        // Assert
        expect(result.isSuccess, isTrue);
        final loginResponse = result.successValue!;
        expect(loginResponse.token, equals('QpwL5tke4Pnpja7X4'));
        expect(loginResponse.user.id, equals(4));
        expect(loginResponse.user.email, equals(email));
        expect(loginResponse.user.firstName, equals(firstName));
        expect(loginResponse.user.lastName, equals(lastName));

        verify(() => mockNetworkClient.post(
          '/register',
          data: {'email': email, 'password': password},
        )).called(1);
      });

      test('should throw ServerException when registration data is invalid', () async {
        // Arrange
        when(() => mockNetworkClient.post(
          '/register',
          data: any(named: 'data'),
        )).thenThrow(DioException(
          response: Response(
            statusCode: 400,
            requestOptions: RequestOptions(path: '/register'),
          ),
          requestOptions: RequestOptions(path: '/register'),
        ));

        // Act & Assert
        expect(
          () => dataSource.register(email: 'invalid', password: password),
          throwsA(isA<ServerException>().having(
            (e) => e.message,
            'message',
            'Registration failed - invalid data',
          )),
        );
      });

      test('should throw ServerException for other HTTP errors', () async {
        // Arrange
        when(() => mockNetworkClient.post(
          '/register',
          data: any(named: 'data'),
        )).thenThrow(DioException(
          response: Response(
            statusCode: 500,
            requestOptions: RequestOptions(path: '/register'),
          ),
          requestOptions: RequestOptions(path: '/register'),
          message: 'Server error',
        ));

        // Act & Assert
        expect(
          () => dataSource.register(email: email, password: password),
          throwsA(isA<ServerException>().having(
            (e) => e.message,
            'message',
            contains('Registration failed'),
          )),
        );
      });
    });

    group('error handling', () {
      test('should handle unexpected exceptions', () async {
        // Arrange
        when(() => mockNetworkClient.post(
          '/login',
          data: any(named: 'data'),
        )).thenThrow(Exception('Unexpected error'));

        // Act & Assert
        expect(
          () => dataSource.login(email: 'test@test.com', password: 'password'),
          throwsA(isA<ServerException>().having(
            (e) => e.message,
            'message',
            contains('Unexpected error during login'),
          )),
        );
      });
    });
  });
}