import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_feed/core/constants/api_constants.dart';
import 'package:mini_feed/core/network/network_client.dart';

void main() {
  late NetworkClient networkClient;
  
  setUp(() {
    networkClient = NetworkClient();
  });
  
  group('NetworkClient', () {
    test('should initialize with correct base options', () {
      // Arrange & Act
      final dio = networkClient.dio;
      
      // Assert
      expect(
        dio.options.connectTimeout,
        const Duration(milliseconds: ApiConstants.connectTimeout),
      );
      expect(
        dio.options.receiveTimeout,
        const Duration(milliseconds: ApiConstants.receiveTimeout),
      );
      expect(
        dio.options.headers['Content-Type'],
        'application/json',
      );
      expect(
        dio.options.headers['Accept'],
        'application/json',
      );
    });
    
    test('should set auth token correctly', () {
      // Arrange
      const token = 'test_token_123';
      
      // Act
      networkClient.setAuthToken(token);
      
      // Assert
      expect(
        networkClient.dio.options.headers['Authorization'],
        'Bearer $token',
      );
    });
    
    test('should clear auth token correctly', () {
      // Arrange
      const token = 'test_token_123';
      networkClient.setAuthToken(token);
      
      // Act
      networkClient.clearAuthToken();
      
      // Assert
      expect(
        networkClient.dio.options.headers.containsKey('Authorization'),
        false,
      );
    });
    
    test('should have network interceptor added', () {
      // Arrange & Act
      final interceptors = networkClient.dio.interceptors;
      
      // Assert
      expect(interceptors.isNotEmpty, true);
    });
  });
}