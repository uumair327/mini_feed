import 'package:dio/dio.dart';

import '../utils/logger.dart';

/// Custom interceptor for network requests
class NetworkInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    Logger.network(
      options.method,
      '${options.baseUrl}${options.path}',
      options.data as Map<String, dynamic>?,
    );
    
    // Add request timestamp
    options.extra['request_time'] = DateTime.now().millisecondsSinceEpoch;
    
    super.onRequest(options, handler);
  }
  
  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final requestTime = response.requestOptions.extra['request_time'] as int?;
    final responseTime = DateTime.now().millisecondsSinceEpoch;
    final duration = requestTime != null ? responseTime - requestTime : 0;
    
    Logger.debug(
      'Response: ${response.statusCode} - '
      '${response.requestOptions.method} '
      '${response.requestOptions.path} '
      '(${duration}ms)',
      'Network',
    );
    
    super.onResponse(response, handler);
  }
  
  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) {
    Logger.error(
      'Network Error: ${err.type} - '
      '${err.requestOptions.method} '
      '${err.requestOptions.path}',
      err,
    );
    
    super.onError(err, handler);
  }
}
