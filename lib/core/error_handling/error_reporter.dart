import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../utils/logger.dart';
import '../storage/storage_service.dart';

/// Service for reporting errors to external services
abstract class ErrorReporter {
  Future<void> initialize();
  Future<void> reportError(Object error, StackTrace? stackTrace, {Map<String, dynamic>? context});
  Future<void> reportMessage(String message, {Map<String, dynamic>? context});
  void setUserContext(String userId, {String? email, String? name});
  void clearUserContext();
}

/// Implementation of ErrorReporter
class ErrorReporterImpl implements ErrorReporter {
  final StorageService _storageService;
  
  static const String _errorQueueKey = 'error_queue';
  static const String _userContextKey = 'user_context';
  
  bool _isInitialized = false;
  Map<String, dynamic>? _userContext;

  ErrorReporterImpl({
    required StorageService storageService,
  }) : _storageService = storageService;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _storageService.initialize();
      
      // Load user context
      final userContextData = await _storageService.get<String>(_userContextKey);
      if (userContextData != null) {
        _userContext = jsonDecode(userContextData) as Map<String, dynamic>;
      }

      // Process any queued errors
      await _processQueuedErrors();

      _isInitialized = true;
      Logger.info('Error reporter initialized');
    } catch (e) {
      Logger.error('Failed to initialize error reporter', e);
    }
  }

  @override
  Future<void> reportError(
    Object error, 
    StackTrace? stackTrace, {
    Map<String, dynamic>? context,
  }) async {
    try {
      final errorReport = _createErrorReport(
        type: 'error',
        message: error.toString(),
        stackTrace: stackTrace?.toString(),
        context: context,
      );

      await _sendOrQueueReport(errorReport);
    } catch (e) {
      Logger.error('Failed to report error', e);
    }
  }

  @override
  Future<void> reportMessage(
    String message, {
    Map<String, dynamic>? context,
  }) async {
    try {
      final errorReport = _createErrorReport(
        type: 'message',
        message: message,
        context: context,
      );

      await _sendOrQueueReport(errorReport);
    } catch (e) {
      Logger.error('Failed to report message', e);
    }
  }

  @override
  void setUserContext(String userId, {String? email, String? name}) {
    _userContext = {
      'userId': userId,
      if (email != null) 'email': email,
      if (name != null) 'name': name,
      'timestamp': DateTime.now().toIso8601String(),
    };

    // Persist user context
    _storageService.store(_userContextKey, jsonEncode(_userContext!));
    
    Logger.info('User context set for error reporting: $userId');
  }

  @override
  void clearUserContext() {
    _userContext = null;
    _storageService.delete(_userContextKey);
    Logger.info('User context cleared for error reporting');
  }

  Map<String, dynamic> _createErrorReport({
    required String type,
    required String message,
    String? stackTrace,
    Map<String, dynamic>? context,
  }) {
    return {
      'type': type,
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
      'platform': Platform.operatingSystem,
      'version': Platform.operatingSystemVersion,
      'isDebug': kDebugMode,
      if (stackTrace != null) 'stackTrace': stackTrace,
      if (_userContext != null) 'user': _userContext,
      if (context != null) 'context': context,
      'appInfo': {
        'version': '1.0.0', // This should come from package info
        'buildNumber': '1',
      },
    };
  }

  Future<void> _sendOrQueueReport(Map<String, dynamic> report) async {
    try {
      // In a real app, you would send this to your error reporting service
      // For now, we'll just log it and queue it for later processing
      
      if (kDebugMode) {
        Logger.info('Error report (debug mode): ${jsonEncode(report)}');
      } else {
        // In production, send to actual service
        await _sendToService(report);
      }
    } catch (e) {
      // If sending fails, queue the report for later
      await _queueReport(report);
      Logger.warning('Failed to send error report, queued for later');
    }
  }

  Future<void> _sendToService(Map<String, dynamic> report) async {
    // This is where you would integrate with actual error reporting services
    // Examples:
    // - Firebase Crashlytics
    // - Sentry
    // - Bugsnag
    // - Custom API endpoint
    
    Logger.info('Sending error report to service: ${report['type']} - ${report['message']}');
    
    // Simulate network call
    await Future.delayed(const Duration(milliseconds: 100));
    
    // For demo purposes, we'll just log it
    // In a real implementation, you would make an HTTP request here
  }

  Future<void> _queueReport(Map<String, dynamic> report) async {
    try {
      final queueData = await _storageService.get<String>(_errorQueueKey);
      List<dynamic> queue = [];
      
      if (queueData != null) {
        queue = jsonDecode(queueData) as List<dynamic>;
      }
      
      queue.add(report);
      
      // Limit queue size to prevent storage bloat
      if (queue.length > 100) {
        queue = queue.sublist(queue.length - 100);
      }
      
      await _storageService.store(_errorQueueKey, jsonEncode(queue));
    } catch (e) {
      Logger.error('Failed to queue error report', e);
    }
  }

  Future<void> _processQueuedErrors() async {
    try {
      final queueData = await _storageService.get<String>(_errorQueueKey);
      if (queueData == null) return;

      final queue = jsonDecode(queueData) as List<dynamic>;
      if (queue.isEmpty) return;

      Logger.info('Processing ${queue.length} queued error reports');

      final processedReports = <Map<String, dynamic>>[];
      
      for (final reportData in queue) {
        try {
          final report = reportData as Map<String, dynamic>;
          await _sendToService(report);
          processedReports.add(report);
        } catch (e) {
          Logger.warning('Failed to process queued error report');
          // Keep failed reports in queue for next attempt
        }
      }

      // Remove processed reports from queue
      if (processedReports.isNotEmpty) {
        final remainingQueue = queue.where((report) => 
          !processedReports.contains(report)).toList();
        
        if (remainingQueue.isEmpty) {
          await _storageService.delete(_errorQueueKey);
        } else {
          await _storageService.store(_errorQueueKey, jsonEncode(remainingQueue));
        }
        
        Logger.info('Processed ${processedReports.length} queued error reports');
      }
    } catch (e) {
      Logger.error('Failed to process queued errors', e);
    }
  }
}

/// Mock error reporter for testing
class MockErrorReporter implements ErrorReporter {
  final List<Map<String, dynamic>> reportedErrors = [];
  final List<String> reportedMessages = [];
  
  @override
  Future<void> initialize() async {
    // Mock implementation
  }

  @override
  Future<void> reportError(
    Object error, 
    StackTrace? stackTrace, {
    Map<String, dynamic>? context,
  }) async {
    reportedErrors.add({
      'error': error.toString(),
      'stackTrace': stackTrace?.toString(),
      'context': context,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> reportMessage(
    String message, {
    Map<String, dynamic>? context,
  }) async {
    reportedMessages.add(message);
  }

  @override
  void setUserContext(String userId, {String? email, String? name}) {
    // Mock implementation
  }

  @override
  void clearUserContext() {
    // Mock implementation
  }
}