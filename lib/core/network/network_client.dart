import 'package:dio/dio.dart';

import '../constants/api_constants.dart';
import '../utils/error_handler.dart';
import '../utils/logger.dart';
import 'network_interceptor.dart';

/// Network client using Dio for HTTP requests
class NetworkClient {
  late final Dio _dio;
  
  NetworkClient() {
    _dio = Dio(_getBaseOptions());
    _setupInterceptors();
  }
  
  /// Get base options for Dio configuration
  BaseOptions _getBaseOptions() => BaseOptions(
        connectTimeout: const Duration(
          milliseconds: ApiConstants.connectTimeout,
        ),
        receiveTimeout: const Duration(
          milliseconds: ApiConstants.receiveTimeout,
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
  
  /// Setup interceptors for logging and error handling
  void _setupInterceptors() {
    _dio.interceptors.addAll([
      NetworkInterceptor(),
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: true,
        responseHeader: false,
        error: true,
        logPrint: (object) => Logger.network('Dio', object.toString()),
      ),
    ]);
  }
  
  /// Perform GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } on DioException catch (e) {
      throw ErrorHandler.handleDioError(e);
    } catch (e) {
      Logger.error('Unexpected error in GET request', e);
      rethrow;
    }
  }
  
  /// Perform POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } on DioException catch (e) {
      throw ErrorHandler.handleDioError(e);
    } catch (e) {
      Logger.error('Unexpected error in POST request', e);
      rethrow;
    }
  }
  
  /// Perform PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } on DioException catch (e) {
      throw ErrorHandler.handleDioError(e);
    } catch (e) {
      Logger.error('Unexpected error in PUT request', e);
      rethrow;
    }
  }
  
  /// Perform PATCH request
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } on DioException catch (e) {
      throw ErrorHandler.handleDioError(e);
    } catch (e) {
      Logger.error('Unexpected error in PATCH request', e);
      rethrow;
    }
  }

  /// Perform DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } on DioException catch (e) {
      throw ErrorHandler.handleDioError(e);
    } catch (e) {
      Logger.error('Unexpected error in DELETE request', e);
      rethrow;
    }
  }
  
  /// Set authorization token for requests
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
    Logger.debug('Auth token set for network requests');
  }
  
  /// Clear authorization token
  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
    Logger.debug('Auth token cleared from network requests');
  }
  
  /// Get the underlying Dio instance (for advanced usage)
  Dio get dio => _dio;
}
