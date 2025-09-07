import 'dart:io';

import 'package:dio/dio.dart';

import '../constants/error_messages.dart';
import '../errors/exceptions.dart';
import '../errors/failures.dart';

/// Utility class for handling and converting errors
class ErrorHandler {
  /// Converts exceptions to failures for the domain layer
  static Failure handleException(Exception exception) {
    if (exception is NetworkException) {
      return NetworkFailure(exception.message);
    } else if (exception is CacheException) {
      return CacheFailure(exception.message);
    } else if (exception is AuthException) {
      return AuthFailure(exception.message);
    } else if (exception is ServerException) {
      return ServerFailure(exception.message, exception.statusCode);
    } else if (exception is ParsingException) {
      return ParsingFailure(exception.message);
    } else if (exception is ValidationException) {
      return ValidationFailure(exception.message);
    } else {
      return UnexpectedFailure(exception.toString());
    }
  }
  
  /// Converts Dio errors to appropriate exceptions
  static Exception handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkException(ErrorMessages.connectionTimeout);
      
      case DioExceptionType.connectionError:
        if (error.error is SocketException) {
          return const NetworkException(ErrorMessages.noInternetConnection);
        }
        return NetworkException(error.message ?? ErrorMessages.unexpectedError);
      
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode ?? 0;
        final message = _getStatusCodeMessage(statusCode);
        return ServerException(message, statusCode);
      
      case DioExceptionType.cancel:
        return const NetworkException(ErrorMessages.requestCancelled);
      
      case DioExceptionType.badCertificate:
        return const NetworkException('SSL certificate error');
      
      case DioExceptionType.unknown:
        return NetworkException(
          error.message ?? ErrorMessages.unexpectedError,
        );
    }
  }
  
  /// Gets user-friendly message for HTTP status codes
  static String _getStatusCodeMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Bad request. Please check your input';
      case 401:
        return ErrorMessages.invalidCredentials;
      case 403:
        return 'Access forbidden';
      case 404:
        return ErrorMessages.dataNotFound;
      case 422:
        return 'Invalid data provided';
      case 429:
        return 'Too many requests. Please try again later';
      case 500:
        return ErrorMessages.serverError;
      case 502:
        return 'Bad gateway. Server is temporarily unavailable';
      case 503:
        return 'Service unavailable. Please try again later';
      default:
        return ErrorMessages.serverError;
    }
  }
  
  /// Gets user-friendly error message from failure
  static String getErrorMessage(Failure failure) {
    if (failure is NetworkFailure) {
      return '${failure.message}\n${ErrorMessages.checkConnection}';
    } else if (failure is AuthFailure) {
      return failure.message;
    } else if (failure is ServerFailure) {
      return '${failure.message}\n${ErrorMessages.tryAgain}';
    } else if (failure is ValidationFailure) {
      return failure.message;
    } else {
      return '${failure.message}\n${ErrorMessages.contactSupport}';
    }
  }
}
